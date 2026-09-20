# AgroControl SaaS

Gestão de rebanho em Flutter + Supabase, com autenticação, múltiplas fazendas por usuário, fotos privadas, linha do tempo do animal e BI.

## Backend ativo

- Supabase: projeto **AgroControl SaaS**
- Região: São Paulo (`sa-east-1`)
- Auth: e-mail e senha
- Database: PostgreSQL com RLS por fazenda
- Storage privado: `animal-media`
- Edge Function: `invite-farm-member`
- Usuários podem pertencer a várias fazendas com papéis `owner`, `admin`, `member` e `viewer`.

## Recursos

- Dashboard colorido com a identidade AgroControl.
- Cadastro e busca de animais.
- Foto principal e fotos históricas por data/tipo.
- Registros de nascimento, evolução, vacinação, saúde, documentos e outros.
- Pesagens com atualização automática do peso atual.
- Vacinas/tratamentos com próxima data.
- Linha do tempo unificada do animal.
- BI: KPIs, peso médio mensal, composição do rebanho, lotes e insights.
- Equipe por fazenda com convite por e-mail.
- RLS e Storage policies para isolamento entre fazendas.
- CI com `flutter analyze`, `flutter test` e `flutter build web`.

## Executar

Requer Flutter estável com Dart 3.10+.

```bash
flutter pub get
flutter run -d chrome
```

A URL e a publishable key do Supabase já possuem defaults seguros para cliente em `lib/core/app_config.dart`. Também podem ser substituídas no build:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

Nunca coloque service-role key no aplicativo.

## Deploy Web

O `render.yaml` prepara o deploy estático no Render. O CI do GitHub também valida o build Web em cada push.

## Banco

As mudanças do banco foram aplicadas através de migrations no projeto Supabase. As tabelas principais são:

`profiles`, `farms`, `farm_members`, `animals`, `weighings`, `health_events` e `animal_media`.

Veja também [docs/QA_CHECKLIST.md](docs/QA_CHECKLIST.md).
