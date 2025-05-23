require ecs
require app
require strings
require DagorSystem
require ecs.ecs_template


[ecs_template]
struct QuitAfterLoadTime
  quit_after_load_time : float
  quitAtTime : float

[es(tag=dev, on_event=EventLevelLoaded)]
def add_quit_entity_from_args(evt : Event)
  let arg = dgs_get_argv("quit_in_time")
  if arg == ""
    return

  var time = -1.0
  var res : ConversionResult
  var ofs : int
  let input = float(arg, res, ofs)
  if res == ConversionResult ok && ofs == length(arg)
    time = input
  else
    logerr("Failed to parse float from quit_in_time argument: '{arg}'")
    return

  if time < 0.0
    return

  let found = find_query() <| $ [es(REQUIRE=quitAtTime)] (var quit_after_load_time : float&)
    debug("Set existing quit_after_load_time to {time} from command line param")
    quit_after_load_time = time
    return true

  if !found
    createEntity("QuitAfterLoadTime") <| $(init)
      init |> set("quit_after_load_time", time)
      init |> set("quitAtTime", -1.0)
    debug("Created new quit_after_load_time {time} from command line param")


[es(tag=dev, on_event=EventLevelLoaded, on_appear, after=add_quit_entity_from_args)]
def set_quit_time_on_level_load(evt : Event; quit_after_load_time : float; var quitAtTime : float&)
  // if entity was created after level, EventLevelLoaded wont trigger hence the on_appear
  // if entity was created before level on_appear, we want to set time only on EventLevelLoaded hence the query
  query() <| $ [es(REQUIRE=level)] ()
    quitAtTime = get_sync_time() + quit_after_load_time
    debug("Will auto quit at time {quitAtTime}")


[es(tag=dev, no_order)]
def quit_after_time(info : UpdateStageInfoAct; quitAtTime : float)
  if quitAtTime > 0.0 && info.curTime > quitAtTime
    exit_game("dev quit at time {quitAtTime}")
