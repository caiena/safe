module SAFE
  class WorkflowNotFound < StandardError; end
  class DependencyLevelTooDeep < StandardError; end
  # Levantado quando não foi possível adquirir o lock distribuído dentro do
  # tempo limite (substitui RedisMutex::LockError após a remoção do redis-mutex).
  class LockError < StandardError; end
end
