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
- Integer-based monetary calculations for precision
- Stream processing for efficient memory usage
- Clear separation of concerns through contexts

### Dependencies

The project uses minimal external dependencies:

1. Poison (~> 6.0)
   - Purpose: JSON parsing/encoding
   - Justification: Industry standard for Elixir JSON handling

2. Decimal (~> 2.0)
   - Purpose: Use Decimal for tax values presentation
   - Justification: Decimal numbers are better handled by Poison for stderr JSON output, as Jason tends to convert large numbers to scientific notation

Development dependencies:
- Credo: Code style checking
- Dialyxir: Static type analysis
- ExCoveralls: Test coverage reporting

## Installation

### Prerequisites
- Elixir 1.16 or later
- Erlang/OTP 24 or later

### System-wide Installation

For Linux/MacOS systems, you can install the executable system-wide:

```bash
# Create installation script

cat  >  install.sh  <<  'EOF'
#!/bin/bash
# install elixir/erlang
asdf install

# get deps
mix deps.get

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
chmod  +x  install.sh
# Run installation
./install.sh
```

## Usage

* Process operations from an input file:
```bash
$ ./capital_gains < operations.json 
```
* You can run capital_gains directly (from your ```$PATH/bin```:
```bash
$ capital_gains < operations.json 
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
$ mix test
```

### Coverage Reports

Generate coverage reports:


### Basic coverage report
```bash
$ MIX_ENV=test mix coveralls
```

### Code Quality

Run static analysis:
```bash
$ mix dialyzer --format short
```

Check code style:
```bash
$ mix credo --strict
```

## Additional Notes

1. Performance Considerations
   - Stream processing for memory efficiency
   - Integer arithmetic for precision
   - Immutable state for reliability

2. Testing Strategy
   - Integration tests for CLI
   - High code coverage ( 97.2%)

3. Future Improvements
   - Multiple currency support
   - Transaction logging
   - API integration

## License

MIT License - see LICENSE file for details.