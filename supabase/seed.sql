-- Dados de exemplo para desenvolvimento local
insert into public.setores (nome, departamento, ordem) values
  ('Recepção', 'Administrativo', 1),
  ('RH', 'Administrativo', 2),
  ('Financeiro', 'Administrativo', 3),
  ('Vendas', 'Comercial', 4),
  ('Expedição', 'Comercial', 5);

insert into public.ramais (setor_id, nome_local, responsavel, numero)
select id, nome, null, case nome
  when 'Recepção' then '200'
  when 'RH' then '210'
  when 'Financeiro' then '220'
  when 'Vendas' then '300'
  when 'Expedição' then '310'
end
from public.setores;
