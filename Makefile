PROJECT = base_app
REBAR = `which rebar || ./rebar`

all: deps app

# Application.

deps:
	@$(REBAR) get-deps

app:
	@$(REBAR) compile

clean:
	@$(REBAR) clean
	rm -f erl_crash.dump

clean-docs:
	rm -f doc/*.css
	rm -f doc/*.html
	rm -f doc/*.png
	rm -f doc/edoc-info

# Tests.

deps-test:
	@$(REBAR) -C rebar.tests.config get-deps

tests: deps-test app ct

inttests: deps-test app intct

ct: deps
	@$(REBAR) -C rebar.tests.config ct skip_deps=true

intct: deps
	@$(REBAR) -C rebar.tests.config ct skip_deps=true

eunit: deps
	@$(REBAR) -C rebar.eunit.config eunit skip_deps=true

new:
	@$(REBAR) ct skip_deps=true

# Dializer.

build-plt: deps app
	@dialyzer --build_plt --output_plt .$(PROJECT).plt \
            --apps erts kernel stdlib sasl inets crypto public_key ssl

dialyze:
	@dialyzer --src src --plt .$(PROJECT).plt --no_native \
            -Werror_handling -Wrace_conditions -Wunmatched_returns
