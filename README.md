```markdown
# Capital Gains Tax Calculator

A command-line tool for calculating capital gains tax on stock market operations according to Brazilian tax rules.

## Technical Overview

### Architecture Decisions

This project follows Domain-Driven Design (DDD) principles with clear bounded contexts:

1. Trading Context
   - Handles stock operations
   - Manages portfolio state
   - Calculates weighted averages

2. Tax Context
   - Implements tax rules
   - Handles tax calculations
   - Manages loss deductions

3. Shared Kernel
   - Common value objects
   - Error handling
   - Type definitions

4. Infrastructure Layer
   - CLI interface
   - File handling
   - I/O processing

Key architectural decisions:
- Immutable data structures for reliable state management
- Railway-oriented programming for error handling
- Integer-based monetary calculations for precision
- Stream processing for efficient memory usage
- Clear separation of concerns through contexts

### Dependencies

The project uses minimal external dependencies:

1. Jason (~> 1.4)
   - Purpose: JSON parsing/encoding
   - Justification: Industry standard for Elixir JSON handling

2. Optimus (~> 0.2)
   - Purpose: Command-line argument parsing
   - Justification: Provides CLI argument handling with built-in help generation

Development dependencies:
- Credo: Code style checking
- Dialyxir: Static type analysis
- ExCoveralls: Test coverage reporting

## Installation

### Prerequisites
- Elixir 1.16 or later
- Erlang/OTP 24 or later

### Building from Source

1. Install tools-versions using asdf:
```bash
   asdf install
```

2. Get dependencies:
```bash
mix deps.get
```

3. Compile the project:
```bash
mix compile
```

4. Build the executable:
```bash
mix escript.build
```

### System-wide Installation

For Linux/MacOS systems, you can install the executable system-wide:

```bash
# Create installation script
cat > install.sh << 'EOF'
#!/bin/bash

# install elixir/erlang
asdf install

# get deps
mix deps

# Build the executable
mix escript.build

# Create bin directory if it doesn't exist
mkdir -p $HOME/bin

# Copy executable to bin directory
cp capital_gains $HOME/bin/

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo 'export PATH="$HOME/bin:$PATH"' >> $HOME/.bashrc
    echo 'Please restart your terminal or run: source $HOME/.bashrc'
fi

echo "Installation complete!"
EOF

# Make script executable
chmod +x install.sh

# Run installation
./install.sh
```

## Usage

### Basic Usage

Process operations from stdin:
```bash
cat operations.json | capital_gains
```

Process operations from file:
```bash
capital_gains -f operations.json
```

Enable verbose output:
```bash
capital_gains -f operations.json -v
```

### Input Format

Operations should be provided in JSON format, one operation list per line:
```json
[{"operation":"buy", "unit-cost":10.00, "quantity": 100}]
[{"operation":"sell", "unit-cost":15.00, "quantity": 50}]
```

### Output Format

Results are returned in JSON format, one result per line:
```json
[{"tax":0.00}]
[{"tax":0.00}]
```

## Testing

### Test Categories

The project separates tests into two categories:

1. Unit Tests:
   - Fast execution
   - No I/O operations
   - Isolated components
   - Clear output

2. CLI Integration Tests:
   - Tests involving I/O operations
   - Full command-line interface testing
   - Multiple operation sequences
   - Complex scenarios

### Running Tests

Run all tests:
```bash
mix test
```

### Coverage Reports

Generate coverage reports:

```bash
# Basic coverage report
MIX_ENV=test mix coveralls

### Code Quality

Run static analysis:
```bash
mix dialyzer --format short
```

Check code style:
```bash
mix credo
```

## Additional Notes

1. Tax Rules Implementation
   - 20% tax rate on profits
   - R$ 20,000.00 tax threshold per operation
   - Loss carryforward for future profit deduction
   - Weighted average cost basis calculation

2. Performance Considerations
   - Stream processing for memory efficiency
   - Integer arithmetic for precision
   - Immutable state for reliability

3. Error Handling
   - Clear error messages
   - Proper error propagation
   - Safe error recovery
   - Input validation

4. Testing Strategy
   - Comprehensive unit tests
   - Integration tests for CLI
   - Property-based testing
   - High code coverage

5. Future Improvements
   - Configuration file support
   - Multiple currency support
   - Transaction logging
   - API integration

## License

MIT License - see LICENSE file for details.
```