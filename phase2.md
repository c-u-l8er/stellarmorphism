# Stellarmorphism Phase 2: Cosmic Design Patterns 🌌

## Overview

Phase 2 introduces **stellar design patterns** as first-class macros that leverage Stellarmorphism's ADT foundation. These patterns provide ergonomic abstractions for common architectural needs while maintaining type safety and stellar theming.

## Pattern Categories

### 🏭 Creational Patterns (Factories)

Build complex structures through elegant construction patterns.

### 🔗 Structural Patterns (Composites) 

Compose and combine stellar types into larger architectural units.

### ⚡ Behavioral Patterns (State/Observer)

Manage dynamic behavior and communication between stellar objects.

---

## 🏭 Creational Patterns

### `stellarfactory` - Cosmic Factory Pattern

Creates configurable factories for stellar types with validation and defaults.

```elixir
defmodule UserFactory do
  use Stellarmorphism
  
  defplanet User do
    orbitals do
      moon id :: String.t()
      moon name :: String.t() 
      moon email :: String.t()
      moon role :: atom()
      moon created_at :: DateTime.t()
    end
  end
  
  stellarfactory UserFactory do
    creates User
    
    templates do
      template :admin do
        id: &generate_id/0
        name: "Admin User"
        email: &generate_admin_email/0
        role: :admin
        created_at: &DateTime.utc_now/0
      end
      
      template :basic_user do
        id: &generate_id/0
        role: :user
        created_at: &DateTime.utc_now/0
      end
      
      template :guest do
        id: &generate_id/0
        name: "Guest"
        role: :guest
        created_at: &DateTime.utc_now/0
      end
    end
    
    validations do
      validate :email, &valid_email?/1
      validate :name, &(String.length(&1) > 0)
    end
  end
end

# Usage anywhere in codebase
admin = UserFactory.create(:admin, %{name: "Alice"})
guest = UserFactory.create(:guest)
user = UserFactory.create(:basic_user, %{name: "Bob", email: "bob@test.com"})

# Batch creation
users = UserFactory.create_batch(:basic_user, 10, fn i -> 
  %{name: "User#{i}", email: "user#{i}@test.com"}
end)
```

### `stellarbuilder` - Fluent Builder Pattern

Creates fluent builders for complex stellar constructions.

```elixir
defmodule DatabaseConfig do
  use Stellarmorphism
  
  defplanet DatabaseConfig do
    orbitals do
      moon host :: String.t()
      moon port :: integer()
      moon database :: String.t()
      moon credentials :: Credentials.t()
      moon pool_size :: integer()
      moon timeout :: integer()
      moon ssl_config :: SSLConfig.t() | nil
    end
  end
  
  stellarbuilder DatabaseBuilder do
    builds DatabaseConfig
    
    fluent_methods do
      def host(builder, hostname) do
        put_field(builder, :host, hostname)
      end
      
      def port(builder, port_num) when is_integer(port_num) do
        put_field(builder, :port, port_num)
      end
      
      def database(builder, db_name) do
        put_field(builder, :database, db_name)
      end
      
      def with_credentials(builder, username, password) do
        creds = Credentials.new(%{username: username, password: password})
        put_field(builder, :credentials, creds)
      end
      
      def pool_size(builder, size) when size > 0 do
        put_field(builder, :pool_size, size)
      end
      
      def enable_ssl(builder, ssl_opts \\ %{}) do
        ssl_config = SSLConfig.new(ssl_opts)
        put_field(builder, :ssl_config, ssl_config)
      end
    end
    
    validations do
      require [:host, :port, :database, :credentials]
      validate :port, &(&1 > 0 and &1 < 65536)
    end
    
    defaults do
      port: 5432
      pool_size: 10
      timeout: 15_000
    end
  end
end

# Usage anywhere in codebase
config = DatabaseBuilder.new()
  |> DatabaseBuilder.host("localhost")
  |> DatabaseBuilder.port(5432)
  |> DatabaseBuilder.database("myapp")
  |> DatabaseBuilder.with_credentials("user", "pass")
  |> DatabaseBuilder.pool_size(20)
  |> DatabaseBuilder.enable_ssl()
  |> DatabaseBuilder.build()
```

### `stellarprototype` - Prototype Pattern with Cloning

Creates clonable prototypes for stellar types.

```elixir
defmodule ConfigTemplates do
  use Stellarmorphism
  
  defplanet AppConfig do
    orbitals do
      moon environment :: atom()
      moon database_url :: String.t()
      moon api_keys :: %{atom() => String.t()}
      moon feature_flags :: %{atom() => boolean()}
      moon logging_level :: atom()
    end
  end
  
  stellarprototype ConfigPrototypes do
    prototypes AppConfig
    
    registry do
      prototype :development do
        environment: :dev
        database_url: "postgresql://localhost/myapp_dev"
        api_keys: %{stripe: "sk_test_...", sendgrid: "SG..."}
        feature_flags: %{new_ui: true, beta_features: true}
        logging_level: :debug
      end
      
      prototype :production do
        environment: :prod
        database_url: {:system, "DATABASE_URL"}
        api_keys: %{stripe: {:system, "STRIPE_KEY"}, sendgrid: {:system, "SENDGRID_KEY"}}
        feature_flags: %{new_ui: false, beta_features: false}
        logging_level: :info
      end
      
      prototype :testing do
        environment: :test
        database_url: "postgresql://localhost/myapp_test"
        api_keys: %{stripe: "sk_test_fake", sendgrid: "SG_test_fake"}
        feature_flags: %{new_ui: true, beta_features: true}
        logging_level: :warn
      end
    end
  end
end

# Usage anywhere in codebase
dev_config = ConfigPrototypes.clone(:development)
custom_prod = ConfigPrototypes.clone(:production, %{
  logging_level: :debug,
  feature_flags: %{beta_features: true}
})

# Create variations
staging_config = ConfigPrototypes.clone(:production)
  |> ConfigPrototypes.modify(%{environment: :staging})
```

---

## 🔗 Structural Patterns

### `stellarcomposite` - Tree/Composite Structures

Creates hierarchical composites using asteroid recursion.

```elixir
defmodule UIComponents do
  use Stellarmorphism
  
  defstar UIComponent do
    layers do
      core Text, 
        content :: String.t(),
        style :: %{atom() => any()}
      core Button,
        label :: String.t(),
        action :: function(),
        disabled :: boolean()
      core Container,
        children :: [asteroid(UIComponent)],
        layout :: atom(),
        style :: %{atom() => any()}
    end
  end
  
  stellarcomposite UITree do
    composes UIComponent
    
    operations do
      def render(%UIComponent{} = component) do
        fission component do
          core Text, content: text, style: style ->
            render_text(text, style)
          
          core Button, label: label, action: action, disabled: disabled ->
            render_button(label, action, disabled)
            
          core Container, children: children, layout: layout, style: style ->
            rendered_children = Enum.map(children, &render/1)
            render_container(rendered_children, layout, style)
        end
      end
      
      def find_by_id(component, target_id) do
        fission component do
          core Container, children: children ->
            Enum.find_value(children, &find_by_id(&1, target_id))
          
          component ->
            if get_id(component) == target_id, do: component, else: nil
        end
      end
      
      def update_component(component, target_id, updater_fn) do
        fission component do
          core Container, children: children, layout: layout, style: style ->
            updated_children = Enum.map(children, &update_component(&1, target_id, updater_fn))
            core Container, children: updated_children, layout: layout, style: style
            
          component ->
            if get_id(component) == target_id do
              updater_fn.(component)
            else
              component
            end
        end
      end
    end
  end
end

# Usage anywhere in codebase
ui_tree = core Container,
  children: [
    asteroid(core Text, content: "Welcome!", style: %{font_size: 24}),
    asteroid(core Button, label: "Click Me", action: &handle_click/0, disabled: false),
    asteroid(core Container,
      children: [
        asteroid(core Text, content: "Nested content", style: %{}),
        asteroid(core Button, label: "Nested Button", action: &nested_action/0, disabled: false)
      ],
      layout: :vertical,
      style: %{padding: 10}
    )
  ],
  layout: :horizontal,
  style: %{background: "white"}

rendered = UITree.render(ui_tree)
button_component = UITree.find_by_id(ui_tree, "main-button")
```

### `stellarbridge` - Adapter/Bridge Pattern

Bridges between different stellar type systems.

```elixir
defmodule DataBridges do
  use Stellarmorphism
  
  # Legacy system types
  defplanet LegacyUser do
    orbitals do
      moon user_id :: integer()
      moon full_name :: String.t()
      moon email_address :: String.t()
    end
  end
  
  # New system types  
  defplanet ModernUser do
    orbitals do
      moon id :: String.t()
      moon first_name :: String.t()
      moon last_name :: String.t()
      moon email :: String.t()
      moon profile :: UserProfile.t()
    end
  end
  
  stellarbridge UserBridge do
    bridges LegacyUser <-> ModernUser
    
    transformations do
      # Legacy to Modern
      transform LegacyUser -> ModernUser do |legacy|
        [first_name, last_name] = String.split(legacy.full_name, " ", parts: 2)
        
        ModernUser.new(%{
          id: "user_#{legacy.user_id}",
          first_name: first_name || "",
          last_name: last_name || "",
          email: legacy.email_address,
          profile: UserProfile.default()
        })
      end
      
      # Modern to Legacy
      transform ModernUser -> LegacyUser do |modern|
        user_id = modern.id |> String.replace("user_", "") |> String.to_integer()
        
        LegacyUser.new(%{
          user_id: user_id,
          full_name: "#{modern.first_name} #{modern.last_name}",
          email_address: modern.email
        })
      end
    end
    
    validations do
      validate_transform LegacyUser -> ModernUser, &valid_modern_user?/1
      validate_transform ModernUser -> LegacyUser, &valid_legacy_user?/1
    end
  end
end

# Usage anywhere in codebase
legacy_user = LegacyUser.new(%{user_id: 123, full_name: "John Doe", email_address: "john@example.com"})
modern_user = UserBridge.transform(legacy_user, to: ModernUser)
back_to_legacy = UserBridge.transform(modern_user, to: LegacyUser)

# Batch transformations
modern_users = UserBridge.transform_batch(legacy_users, to: ModernUser)
```

---

## ⚡ Behavioral Patterns

### `stellarobserver` - Observer/PubSub Pattern

Creates reactive observers for stellar state changes.

```elixir
defmodule GameState do
  use Stellarmorphism
  
  defstar GameState do
    layers do
      core Menu, current_screen :: atom()
      core Playing, 
        player :: Player.t(),
        enemies :: [Enemy.t()],
        score :: integer(),
        level :: integer()
      core Paused,
        saved_state :: GameState.t(),
        pause_reason :: String.t()
      core GameOver,
        final_score :: integer(),
        duration :: integer()
    end
  end
  
  stellarobserver GameObserver do
    observes GameState
    
    events do
      on_enter :Playing do |state|
        # State entered Playing
        Logger.info("Game started: Level #{state.level}")
        Metrics.increment("games.started")
      end
      
      on_exit :Playing do |state|
        # State exited Playing
        Logger.info("Game ended: Score #{state.score}")
        save_high_score(state.score)
      end
      
      on_transition :Playing -> :Paused do |from_state, to_state|
        # Specific transition
        Logger.info("Game paused: #{to_state.pause_reason}")
        save_game_state(from_state)
      end
      
      on_field_change :Playing, :score do |old_score, new_score, state|
        # Field-specific changes
        if new_score > old_score + 100 do
          broadcast_achievement("score_milestone", new_score)
        end
      end
      
      on_any_change do |old_state, new_state|
        # Global state change handler
        GameReplay.record_transition(old_state, new_state)
      end
    end
    
    subscriptions do
      # Subscribe external systems
      subscribe PlayerStats, to: [:score, :level]
      subscribe UIManager, to: [:all]
      subscribe SoundManager, to: [:state_transitions]
    end
  end
end

# Usage anywhere in codebase
game_state = core Playing, player: player, enemies: [], score: 0, level: 1

# Observers automatically trigger when state changes
new_state = GameObserver.notify_change(game_state, core Paused, 
  saved_state: game_state, 
  pause_reason: "user_requested"
)

# Manual observation registration
GameObserver.register_observer(MyCustomObserver, events: [:score])
```

### `stellarmachine` - State Machine Pattern

Creates type-safe state machines with stellar transitions.

```elixir
defmodule ConnectionMachine do
  use Stellarmorphism
  
  defstar ConnectionState do
    layers do
      core Disconnected, 
        last_error :: String.t() | nil,
        retry_count :: integer()
      core Connecting,
        attempt :: integer(),
        started_at :: DateTime.t()
      core Connected,
        socket :: port(),
        established_at :: DateTime.t(),
        ping_interval :: integer()
      core Error,
        reason :: String.t(),
        recoverable :: boolean()
    end
  end
  
  stellarmachine ConnectionStateMachine do
    manages ConnectionState
    
    initial_state :Disconnected, retry_count: 0
    
    transitions do
      from :Disconnected do
        to :Connecting, via: :connect, 
          condition: &can_connect?/1,
          action: &start_connection/1
          
        to :Error, via: :connection_failed,
          condition: &max_retries_exceeded?/1
      end
      
      from :Connecting do
        to :Connected, via: :established,
          action: &setup_connection/1
          
        to :Disconnected, via: :connection_timeout,
          action: &increment_retry_count/1
          
        to :Error, via: :fatal_error,
          condition: &is_fatal_error?/1
      end
      
      from :Connected do
        to :Disconnected, via: [:disconnect, :connection_lost],
          action: &cleanup_connection/1
      end
      
      from :Error do
        to :Disconnected, via: :reset,
          condition: &(& &1.recoverable),
          action: &reset_error_state/1
      end
    end
    
    guards do
      defp can_connect?(%{retry_count: count}), do: count < 5
      defp max_retries_exceeded?(%{retry_count: count}), do: count >= 5
      defp is_fatal_error?(%{reason: reason}), do: reason in ["auth_failed", "banned"]
    end
    
    actions do
      defp start_connection(state) do
        %{state | attempt: state.retry_count + 1, started_at: DateTime.utc_now()}
      end
      
      defp setup_connection(state) do
        %{state | established_at: DateTime.utc_now(), ping_interval: 30}
      end
      
      defp increment_retry_count(state) do
        %{state | retry_count: state.retry_count + 1}
      end
    end
  end
end

# Usage anywhere in codebase
{:ok, machine} = ConnectionStateMachine.start_link()

# Trigger transitions
{:ok, new_state} = ConnectionStateMachine.trigger(machine, :connect)
{:ok, connected_state} = ConnectionStateMachine.trigger(machine, :established, socket: socket)

# Query current state
current = ConnectionStateMachine.current_state(machine)
can_disconnect = ConnectionStateMachine.can_trigger?(machine, :disconnect)

# Get available transitions
available_events = ConnectionStateMachine.available_transitions(machine)
```

### `stellarstrategy` - Strategy Pattern

Creates pluggable behavior strategies for stellar types.

```elixir
defmodule PaymentStrategies do
  use Stellarmorphism
  
  defplanet Payment do
    orbitals do
      moon amount :: Money.t()
      moon currency :: String.t()
      moon metadata :: map()
    end
  end
  
  defstar PaymentResult do
    layers do
      core Success, 
        transaction_id :: String.t(),
        processed_at :: DateTime.t()
      core Failed,
        error_code :: String.t(),
        error_message :: String.t(),
        retry_after :: integer() | nil
      core Pending,
        reference :: String.t(),
        estimated_completion :: DateTime.t()
    end
  end
  
  stellarstrategy PaymentProcessor do
    strategies_for Payment -> PaymentResult
    
    strategy :stripe do
      def process(%Payment{} = payment) do
        case Stripe.create_payment_intent(payment.amount, payment.currency) do
          {:ok, intent} ->
            core Success, 
              transaction_id: intent.id,
              processed_at: DateTime.utc_now()
          
          {:error, reason} ->
            core Failed,
              error_code: "stripe_error",
              error_message: reason,
              retry_after: 60
        end
      end
      
      def supports?(%Payment{currency: currency}), do: currency in ["usd", "eur", "gbp"]
      def priority(), do: 1
    end
    
    strategy :paypal do
      def process(%Payment{} = payment) do
        case PayPal.process_payment(payment) do
          {:ok, result} ->
            core Success,
              transaction_id: result.id,
              processed_at: result.created_time
              
          {:pending, ref} ->
            core Pending,
              reference: ref,
              estimated_completion: DateTime.add(DateTime.utc_now(), 300, :second)
        end
      end
      
      def supports?(%Payment{}), do: true  # Supports all currencies
      def priority(), do: 2
    end
    
    strategy :bank_transfer do
      def process(%Payment{} = payment) do
        # Bank transfers are always pending initially
        ref = generate_transfer_reference()
        core Pending,
          reference: ref,
          estimated_completion: DateTime.add(DateTime.utc_now(), 86400, :second)
      end
      
      def supports?(%Payment{amount: %{value: amount}}), do: amount >= 1000
      def priority(), do: 3
    end
  end
end

# Usage anywhere in codebase
payment = Payment.new(%{
  amount: Money.new(5000, :usd),
  currency: "usd",
  metadata: %{order_id: "12345"}
})

# Automatic strategy selection
result = PaymentProcessor.process(payment)  # Uses best strategy

# Manual strategy selection  
result = PaymentProcessor.process(payment, strategy: :stripe)

# Get available strategies for payment
strategies = PaymentProcessor.available_strategies(payment)
# => [:stripe, :paypal, :bank_transfer]

# Fallback processing
result = PaymentProcessor.process_with_fallback(payment, [:stripe, :paypal])
```

---

## 🌐 Global Usage

All patterns are **globally accessible macros** that can be used anywhere in your codebase:

```elixir
# In any module, anywhere in your application:
defmodule MyController do
  # Use factories
  user = UserFactory.create(:admin, %{name: "Alice"})
  
  # Use builders
  config = DatabaseBuilder.new()
    |> DatabaseBuilder.host("localhost")
    |> DatabaseBuilder.build()
  
  # Use state machines
  {:ok, machine} = ConnectionStateMachine.start_link()
  
  # Use observers
  GameObserver.register_observer(self(), events: [:score])
  
  # Use strategies
  result = PaymentProcessor.process(payment)
end
```

## Integration with Phase 1

All patterns leverage **asteroids** and **rockets** from Phase 1:

```elixir
stellarcomposite UITree do
  composes UIComponent
  
  # Uses asteroids for eager child rendering
  children :: [asteroid(UIComponent)]
  
  # Uses rockets for lazy-loaded components
  lazy_sections :: rocket([UIComponent])
end

stellarmachine StateMachine do
  # State history using rockets
  history :: rocket([StateTransition])
  
  # Current state using asteroids
  current :: asteroid(State)
end
```

## Benefits

1. **🎯 Focused Abstractions**: Each pattern solves specific architectural problems
2. **🔧 Type Safety**: All patterns work with Stellarmorphism's type system
3. **🚀 Performance**: Leverage asteroid/rocket evaluation strategies
4. **🌟 Stellar Theming**: Consistent cosmic naming convention
5. **📦 Composable**: Patterns can be combined and nested
6. **🔌 Pluggable**: Easy to extend with custom behaviors

Phase 2 transforms Stellarmorphism from a type system into a **full architectural framework** while maintaining the elegant stellar theme!

---

**Stellarmorphism Phase 2**: Where cosmic types meet stellar architecture! 🌌✨