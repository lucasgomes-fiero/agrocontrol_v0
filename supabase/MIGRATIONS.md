# Supabase — migrations aplicadas

Projeto remoto: `AgroControl SaaS` (`bsbfjvwvdaisnoxvfrqx`), região `sa-east-1`.

Migrations aplicadas no banco de produção:

| Versão | Migration |
| --- | --- |
| 20260919235610 | agrocontrol_saas_core |
| 20260919235644 | harden_rls_and_indexes |
| 20260919235951 | shared_farm_profiles |
| 20260920000108 | profiles_email_for_team |
| 20260920000811 | viewer_read_only |
| 20260920000939 | farm_members_profile_relation |
| 20260920001339 | protect_farm_owner_membership |

## Modelo multi-tenant

- `farms`: unidade de isolamento.
- `farm_members`: vínculo usuário ↔ fazenda e papel.
- `animals`, `weighings`, `health_events`, `animal_media`: sempre possuem `farm_id`.
- RLS bloqueia leitura fora das fazendas em que o usuário é membro.
- `viewer` tem somente leitura.
- `owner`, `admin` e `member` escrevem dados operacionais.
- Exclusão de animal e gestão de equipe exigem owner/admin.
- O bucket privado `animal-media` usa a primeira pasta do path como `farm_id` e aplica as mesmas regras.

## Storage

Bucket privado: `animal-media`.

Estrutura dos paths:

```
<farm_id>/<animal_id>/<timestamp>.<ext>
```

Tamanho máximo por imagem: 10 MB. MIME permitidos: JPEG, PNG e WebP.

## BI

RPCs:

- `farm_dashboard_stats(uuid)`
- `farm_weight_series(uuid, integer)`
- `farm_lot_distribution(uuid)`
- `farm_category_distribution(uuid)`

As RPCs são `SECURITY INVOKER` e respeitam as políticas RLS.

## Segurança

Após a última migration, o Supabase Security Advisor retornou **zero alertas**. Os avisos de performance restantes são apenas índices ainda sem uso, esperado em uma base recém-criada e sem dados.
