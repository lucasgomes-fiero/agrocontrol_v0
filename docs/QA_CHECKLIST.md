# QA — AgroControl SaaS

A pipeline de CI executa análise estática, testes de widgets/modelos e build Web a cada push.

## Fluxos interativos cobertos no código

- Login: entrar, exibir/ocultar senha, esqueci minha senha, criar conta.
- Fazenda: criar primeira fazenda, criar outra fazenda e trocar fazenda.
- Dashboard: atualizar, cadastrar animal, nova pesagem, saúde e abrir BI.
- Animais: busca, filtros, cadastro, abrir detalhes, editar e excluir.
- Animal: adicionar foto, pesagem, saúde e navegar pela linha do tempo.
- Foto: câmera/galeria, tipo, data, legenda e definir foto principal.
- Saúde: tipo, produto/procedimento, data, próxima dose, observação e foto.
- BI: atualizar e renderizar indicadores, tendência de peso, categorias, lotes e insights.
- Equipe: convidar membro, escolher permissão e remover membro.
- Conta: trocar fazenda e sair.

## Validação de produção

1. Criar usuário novo.
2. Criar duas fazendas e confirmar isolamento dos dados.
3. Convidar segundo usuário como membro e confirmar acesso à fazenda.
4. Convidar usuário como viewer e confirmar somente leitura via RLS.
5. Cadastrar animal com foto de nascimento.
6. Adicionar foto de evolução, vacinação com comprovante e pesagem.
7. Validar linha do tempo ordenada.
8. Abrir BI e conferir atualização após novas pesagens/saúde.
9. Sair e entrar novamente.
10. Testar Web em desktop/mobile e Android/iOS antes de release nas lojas.
