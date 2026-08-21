# appchoppon-clientes

Aplicativo consumidor CHOPPON em Flutter, iniciado sobre a API B2C versionada do ERP. O repositorio estava vazio no momento da clonagem; este commit entrega a fundacao executavel do cliente, com login por email/senha, sessao persistida em armazenamento seguro, refresh automatico de access token e dashboard responsivo de consumo/cashback.

## Arquitetura

| Camada | Local | Responsabilidade |
|---|---|---|
| Configuracao | `lib/src/core/config` | Endpoint da API por `--dart-define`, sem segredo embutido. |
| Rede | `lib/src/core/network` | HTTP JSON, Bearer token, refresh e erros tipados. |
| Armazenamento | `lib/src/core/storage` | Access/refresh tokens em `flutter_secure_storage`. |
| Auth | `lib/src/features/auth` | Login, logout e restauracao de sessao. |
| Dashboard | `lib/src/features/dashboard` | Leitura dos periodos de consumo e cashback. |
| UI | `lib/main.dart` | Login, splash, dashboard, refresh e logout responsivos. |

O aplicativo nao calcula cashback, nao altera saldo, nao recebe `customer_id`, nao acessa MySQL e nao controla BLE. Essas responsabilidades permanecem no ERP e no Android TAP.

## API utilizada

A URL padrao e `https://ochoppoficial.com.br/api/v1/`. Para homologacao, sobrescreva sem alterar o codigo:

```bash
flutter run --dart-define=CHOPPON_API_BASE_URL=https://staging.example.com/api/v1/
```

O cliente usa `POST /auth/login.php`, `POST /auth/refresh.php`, `POST /auth/logout.php` e `GET /pontos/dashboard.php`. O contrato completo esta em [`../chopponERP/api/v1/README.md`](../chopponERP/api/v1/README.md).

## Execucao

Com Flutter instalado, execute `flutter pub get`, depois `flutter analyze` e `flutter test`. Para Android, use `flutter run` em um dispositivo ou emulador configurado. Nenhum segredo deve ser colocado em `pubspec.yaml`, no fonte Dart ou em assets.

## Proximas etapas

O repositorio ainda precisa das telas de cadastro, perfil, historico paginado, carteira, ranking, catalogo de unidades/bebidas/promocoes, consentimentos detalhados e suporte. Essas telas devem ser adicionadas depois da validacao do contrato de produto e reutilizar os mesmos repositories/controllers, sem duplicar regras de negocio no cliente.
