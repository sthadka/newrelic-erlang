-module(newrelic).
-compile([export_all]).



app_name() ->
    application:get_env(newrelic, application_name).


license_key() ->
    application:get_env(newrelic, license_key).


get_redirect_host() ->
    Url = "http://collector.newrelic.com/agent_listener/invoke_raw_method?"
        "protocol_version=9&"
        "license_key=" ++ license_key() ++ "&"
        "marshal_format=json&"
        "method=get_redirect_host",

    {ok, {{200, "OK"}, _, Body}} = lhttpc:request(Url, post, [{"Content-Encoding", "identity"}], <<"[]">>, 5000),
    {Struct} = jiffy:decode(Body),
    binary_to_list(proplists:get_value(<<"return_value">>, Struct)).


connect(Host) ->
    Url = "http://" ++ Host ++ "/agent_listener/invoke_raw_method?"
        "protocol_version=9&"
        "license_key=" ++ license_key() ++ "&"
        "marshal_format=json&"
        "method=connect",
    Data = [{[
              {agent_version, <<"1.0">>},
              {app_name, [<<"Statman New Relic Test">>]},
              {host, <<"knutin">>},
              {identifier, <<"Statman New Relic Test">>},
              {pid, 1234},
              {environment, []},
              {language, <<"python">>},
              {settings, {[

                          ]}}
             ]}],

    {ok, {{200, "OK"}, _, Body}} = lhttpc:request(Url, post, [{"Content-Encoding", "identity"}], jiffy:encode(Data), 5000),
    {Struct} = jiffy:decode(Body),
    {Return} = proplists:get_value(<<"return_value">>, Struct),
    proplists:get_value(<<"agent_run_id">>, Return).


push_metric_data(Host, RunId, MetricData) ->
    Url = "http://" ++ Host ++ "/agent_listener/invoke_raw_method?"
        "protocol_version=9&"
        "license_key=" ++ license_key() ++ "&"
        "marshal_format=json&"
        "method=metric_data&"
        "run_id=" ++ integer_to_list(RunId),


    Data = [
            RunId,
            now_to_seconds() - 60,
            now_to_seconds(),
            MetricData
           ],

    lhttpc:request(Url, post, [{"Content-Encoding", "identity"}], jiffy:encode(Data), 5000).


push(Data) ->
    Host = get_redirect_host(),
    RunId = connect(Host),
    push_metric_data(Host, RunId, Data).

push_sample() ->
    Host = get_redirect_host(),
    RunId = connect(Host),
    push_metric_data(Host, RunId, sample_data()).


now_to_seconds() ->
    {MegaSeconds, Seconds, _} = os:timestamp(),
    MegaSeconds * 1000000 + Seconds.


sample_data() ->
    [
     [{[{name, <<"MFA/g8_location_server:call/2">>},
        {scope, <<"WebTransaction/Uri/test">>}]},
      [20,
       2.0030434131622314,
       2.0030434131622314,
       0.10012507438659668,
       0.10023093223571777,
       0.2006091550569522]],

     [{[{name, <<"Database/Redis-HSET">>},
        {scope, <<"WebTransaction/Uri/test">>}]},
      [20,
       2.0030434131622314,
       2.0030434131622314,
       0.10012507438659668,
       0.10023093223571777,
       0.2006091550569522]],

     [{[{name, <<"S3/GET">>},
        {scope, <<"WebTransaction/Uri/test">>}]},
      [20,
       2.0030434131622314,
       2.0030434131622314,
       0.10012507438659668,
       0.10023093223571777,
       0.2006091550569522]],

     [{[{name, <<"WebTransaction">>},
        {scope, <<"">>}]},
      [1,
       2.0055530071258545,
       0.00017213821411132812,
       2.0055530071258545,
       2.0055530071258545,
       4.022242864391558]],

     [{[{name, <<"HttpDispatcher">>},
        {scope, <<"">>}]},
      [1,
       2.0055530071258545,
       0.00017213821411132812,
       2.0055530071258545,
       2.0055530071258545,
       4.022242864391558]],

     [{[{name, <<"Database/allWeb">>},
        {scope, <<"">>}]},
      [1,
       2.0055530071258545,
       0.00017213821411132812,
       2.0055530071258545,
       2.0055530071258545,
       4.022242864391558]],

     [{[{name, <<"Memcache/allWeb">>},
        {scope, <<"">>}]},
      [1,
       2.0055530071258545,
       0.00017213821411132812,
       2.0055530071258545,
       2.0055530071258545,
       4.022242864391558]],

     [{[{name, <<"WebTransaction/Uri/test">>},
        {scope, <<"">>}]},
      [1,
       2.0055530071258545,
       0.00017213821411132812,
       2.0055530071258545,
       2.0055530071258545,
       4.022242864391558]],

     [{[{name, <<"Python/WSGI/Application">>},
        {scope, <<"WebTransaction/Uri/test">>}]},
      [1,
       2.005380868911743,
       7.176399230957031e-05,
       2.005380868911743,
       2.005380868911743,
       4.021552429397218]]

    ].
