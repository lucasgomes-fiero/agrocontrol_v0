# Arquitetura AgroControl SaaS

## Cliente

Flutter Web/mobile com Supabase Flutter. O cliente utiliza apenas a publishable key. Chaves administrativas nunca são incluídas no aplicativo.

## Autenticação

Supabase Auth com e-mail/senha. O trigger `handle_new_user` cria o perfil público interno do usuário.

## Fazendas e permissões

Um usuário pode participar de várias fazendas.

- owner: proprietário, controle total.
- admin: equipe e operação.
- member: operação de rebanho.
- viewer: consulta/BI sem escrita.

A troca de fazenda muda o `farm_id` ativo e todas as consultas são filtradas por ele. A segurança não depende apenas do filtro do app: o PostgreSQL repete a validação através de RLS.

## Fotos e linha do tempo

Fotos ficam no Supabase Storage, nunca dentro da tabela. A tabela `animal_media` guarda metadados como tipo, data, legenda e ligação opcional a um registro sanitário.

A tela do animal combina:

- fotos;
- pesagens;
- vacinas e tratamentos;

em uma linha do tempo ordenada por data.

## BI

Os cálculos agregados são executados no PostgreSQL e retornados por RPC, reduzindo tráfego e mantendo os dados isolados por RLS.

## Convites

A Edge Function `invite-farm-member` usa a service-role apenas dentro do ambiente seguro do Supabase para localizar/convidar um usuário e adicionar o vínculo na fazenda. O chamador precisa estar autenticado e ser owner/admin.
