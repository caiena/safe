# S.A.F.E
## Secure Asynchronous Financial Executor

S.A.F.E. é uma gem criada com base na [gem gush](https://github.com/chaps-io/gush) para a execução de trabalhos assíncronos de forma ordenada, utilizando Redis e [ActiveJob](http://guides.rubyonrails.org/v4.2/active_job_basics.html#introduction).

## Instalação

### 1. Adicinonar `safe` to Gemfile

```ruby
gem 'safe'
```

### 2. Instalar as migrações

```
bundle exec rails g safe:install
```

## Testando

```ruby
rspec spec
```
