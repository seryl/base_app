-module(base_app).

-export([load_config_file/2, load_config/2]).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

%% ===================================================================
%% Public API
%% ===================================================================

get_pool(Pool) ->
  {ok, PoolList} = app_helper:get_env(pools),
  lists:keyfind(Pool, 1, PoolList).

load_config_file(Application, ConfigFile) ->
  {ok, Config} = file:read_file(ConfigFile),
  load_config(Application, Config).

load_config(Application, Config) ->
  Data = jsx:decode(Config, [{labels, atom}]),
  update_configs(Application, Data).

update_configs(_Application, []) -> ok;
update_configs(Application, Data) ->
  [{Key, Value} | Tail] = Data,
  case is_binary(Value) of
    true  -> application:set_env(Application, Key, binary_to_list(Value));
    false -> application:set_env(Application, Key, Value)
  end,
  update_configs(Application, Tail).

%% ===================================================================
%% EUnit tests
%% ===================================================================
-ifdef(TEST).

base_app_test_() ->
    { setup,
      fun setup/0,
      fun cleanup/1,
      [
       fun load_config_test_case/0,
       fun override_config_test_case/0,
       fun get_pool_test_case/0,
      ]
    }.

setup() ->
  ok.

cleanup(_Ctx) ->
  application:set_env(base_app, config_file, "config.json"),
  application:unset_env(base_app, pools),
  ok.

load_config_test_case() ->
  JStr = <<"{\"http_port\": 8080, \"enable_zk\": true, \"user\": \"bob\"}">>,
  load_config(base_app, JStr),
  ?assertEqual({ok, 8080}, application:get_env(base_app, http_port)),
  ?assertEqual({ok, true}, application:get_env(base_app, enable_zk)),
  ?assertEqual({ok, "bob"}, application:get_env(base_app, user)).

load_complex_config_test_case() ->
  ["{\"name\":\"bob\",\"loc\":{\"city\":\"truckee\",",
   "\"region\":\"tahoe\"},\"kids\":[\"joe\",\"sue\"]}"],


override_config_test_case() ->
  load_config(base_app, <<"{\"config_file\": \"/etc/app.json\"}">>),
  ?assertEqual({ok, "/etc/app.json"},
               application:get_env(base_app, config_file)).

get_pool_test_case() ->
  application:set_env(pools,
                      [ {cassandra,
                         [{size, 10},
                          {max_overflow, 20}
                         ], [{nodes, "localhost"} ]}
                      ]),

  Pool = get_pool(cassandra),
  ?assertEqual({cassandra,
                [{size, 10},
                 {max_overflow, 20}
                ], [{nodes, "localhost"} ]}, Pool).

-endif.
