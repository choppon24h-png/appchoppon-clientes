import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/core/network/api_client.dart';
import 'src/core/storage/token_store.dart';
import 'src/features/auth/auth_controller.dart';
import 'src/features/auth/auth_repository.dart';
import 'src/features/dashboard/dashboard_controller.dart';
import 'src/features/dashboard/dashboard_repository.dart';
import 'src/shared/models.dart';

void main() {
  final tokenStore = TokenStore();
  final api = ApiClient(tokenStore: tokenStore);
  final auth = AuthController(AuthRepository(api, tokenStore));
  final dashboard = DashboardController(DashboardRepository(api));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: dashboard),
      ],
      child: const ChoppOnApp(),
    ),
  );
  unawaited(auth.restore());
}

class ChoppOnApp extends StatelessWidget {
  const ChoppOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CHOPPON',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D421E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF9F3),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: Consumer<AuthController>(
        builder: (context, auth, _) {
          if (auth.isLoading) return const SplashPage();
          return auth.isAuthenticated ? const DashboardPage() : const LoginPage();
        },
      ),
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    await auth.login(_email.text, _password.text);
    if (!mounted || auth.errorMessage == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.errorMessage!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.local_drink, size: 64, color: Color(0xFF8D421E)),
                        const SizedBox(height: 12),
                        Text(
                          'CHOPPON',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF8D421E),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seu chopp, sua jornada.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(labelText: 'E-mail'),
                          validator: (value) {
                            if (value == null || !value.contains('@')) return 'Informe um e-mail valido.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Informe sua senha.' : null,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: auth.isLoading ? null : _submit,
                          child: auth.isLoading
                              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Entrar'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Use o cadastro da API CHOPPON v1. O aplicativo nunca armazena senha em texto e nao recebe CPF completo.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();
    final data = controller.data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha jornada'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            if (controller.isLoading && data == null)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.errorMessage != null && data == null)
              _ErrorCard(message: controller.errorMessage!, onRetry: controller.load)
            else if (data != null) ...[
              _WelcomeCard(profile: data.profile, cashback: data.cashbackBalance),
              const SizedBox(height: 20),
              Text('Seu consumo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 760 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth >= 760 ? 1.8 : 1.35,
                    children: [
                      _MetricCard(label: 'Hoje', summary: data.today),
                      _MetricCard(label: 'Semana', summary: data.week),
                      _MetricCard(label: 'Mes', summary: data.month),
                      _MetricCard(label: 'Total', summary: data.total),
                    ],
                  );
                },
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(controller.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.profile, required this.cashback});

  final CustomerProfile profile;
  final double cashback;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF8D421E),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ola, ${profile.name}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Nivel ${profile.level}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  Text('Cashback disponivel: R\$ ${cashback.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.summary});

  final String label;
  final ConsumptionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text('${summary.liters.toStringAsFixed(2)} L', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${summary.count} consumos', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}
