# S.A.F.E
## Secure Asynchronous Flow Executor

S.A.F.E. é uma gem criada com base na [gem gush](https://github.com/chaps-io/gush) para a execução de trabalhos assíncronos de forma ordenada, utilizando Redis e [ActiveJob](http://guides.rubyonrails.org/v4.2/active_job_basics.html#introduction). Esta gem toma como base a implementação utilizada no gush, sendo assim, quase todas suas _features_ estão disponíveis para uso.

Além da execução ordenada de trabalhos assíncronos esta gem monitora outras entidades as quais um _job_ é relacionado, registrando cada uma das etapas de execução.

## Instalação

### 1. Adicinonar `safe` to Gemfile

```ruby
gem 'safe', github: 'caiena/safe', branch: 'master'
```

### 2. Instalar as migrações

Execute o gerador para instalar as migrações no projeto

```
bundle exec rails g safe:install
bundle exec rake db:migrate
```

## Utilização

Um _workflow_ possuí 2 métodos principais (definidos dentro do método `configure`), são eles `link` e `run`, ex:

```ruby
# app/workflows/sample_workflow.rb
class NotificationWorkflow < SAFE::Workflow
  def configure(user_id)

    # método opcional, serve para linkar um objeto que responda ao método :id,
    # possibilitando o vínculo entra um workflow e o registro
    link User.find(user_id)

    run ComputeUserJob, params: { id: user_id }
    run UpdateUserJob, params: { id: user_id }

    run NotifyUserJob, after: [ComputeUserJob, UpdateUserJob], params: { id: user_id }

    run NotifyAdminJob, after: NotifyUserJob
  end
end
```

O método `run` aceita dois parâmetros:

- `after:` onde é passada uma ou mais classes de jobs que precisam ser executados como pré requisitos.

- `params:` hash com parâmetros disponíveis para o job.


Após definir um workflow é preciso definir seus jobs, ex:
```ruby
class ComputeUserJob < SAFE::Job
  # definição dos procedimentos a serem executados
  def perform
    # método com hash de variáveis passadas no workflow
    params #=> {id: 10}
    user = User.find(params[:id])

    # o método track aceita um bloco envolvendo uma etapa de
    # computação. Se o bloco não levantar um erro o método track
    # irá incrementar o número de sucessos do monitor do job em questão
    track { user.compute }
    track { user.finish_computation }
  end

  # número total de passos a serem executados dentro
  # do método perform. Nesse caso, o total são 2 pois
  # temos dois processamentos (um em cada block `track`)
  def total_steps
    2
  end
end
```

Em jobs mais complexos podemos fazer:
```ruby
class UpdateUserJob < SAFE::Job

  def perform
    # o método order_and_track aceita uma coleção
    # de registros e um segundo parâmetro para ordenação.
    # Esse método deve envelopar coleções para o caso
    # de que o Job sofra um erro crítico, ao ser retomado,
    # o job irá iniciar a partir do último id registrado com sucesso.
    order_and_track(orders).each do |order|

      # agora o método track também aceita um objeto que responda a :id,
      # com isso a execução do bloco com sucesso registrará o id do último
      # registro executado com sucesso
      track(order) { order.compute }
    end
  end

  def total_steps
    orders.count
  end

  def orders
    @orders ||= User.find(params[:id]).orders
  end

  private

  # esse método permite que algumas exceções esperadas
  # evitem a falha de execução do job. Se uma dessas
  # exceções for levantada durante o processamento o método
  # `track` irá incrementar o número de falhas e criará um
  # registro de `error_occurrence` para o job.
  def recoverable_exceptions
    [OrderInvalidException, OrderNotFound]
  end
end
```


## Executanto um workflow

### 1. Inicie o servidor de processos

```
bundle exec sidekiq -q safe
```


### 2. Crie um workflow

```ruby
flow = NotificationWorkflow.create(user.id)
```

### 3. Inicie o workflow

```ruby
flow.start! #=> inicia os jobs em segundo plano
```

### 4. Monitore o progresso

```ruby
flow.reload
flow.status
#=> :running|:finished|:failed
```

`reload` é necessário porque os workflows são atualizados de forma assíncrona.

### 5. Obtendo os resultados persistidos

```ruby
monitor = flow.monitor
monitor #=> SAFE::WorkflowMonitor
monitor.monitorable #=> user<# id: 10>
monitor.jobs

job = monitor.jobs.first
job #=> SAFE::JobMonitor

job.processed
job.total #=> 2
job.successes
job.failures
job.processed

# erros recuperáveis geram ocorrências dentro de um job
occurrence = job.error_occurrences.first
occurrence #=> SAFE::ErrorOccurrence
```
## Expiração

Por padrão as chaves permanecerão indeterminadamente no redis, para evitar um acumulo de armazenamento desnecessário basta configurar o valor em segundos de `ttl`, ex:
```ruby
# config/initializers/safe.rb
SAFE.configure do |config|
  config.ttl = 3600*24*10
end
```

## Testando

A suíte de testes utiliza a gem `combustion` para o setup de uma aplicação rails de teste, então basta rodar a bateria com:

```ruby
rspec spec
```

É possível utilizar o `Guard` para monitorar os arquivos rodando na raiz do projeto:

```
guard
```

## To-Do

- Melhora suíte de tests
- Implementar parâmetros globais em workflow (disponíveis para todos os jobs)
