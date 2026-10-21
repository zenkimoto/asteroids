extends RuntimeTestSuite
## Difficulty curves from the balance resources, checked wave by wave.

const WAVES_CHECKED: int = 30


func suite_name() -> String:
	return "balance"


func uses_game() -> bool:
	return false


func test_wave_difficulty_never_drops() -> void:
	var waves := GameManager.balance.waves
	var previous_count := 0
	var previous_speed := 0.0
	var previous_armored := 0
	for wave in range(1, WAVES_CHECKED + 1):
		var count := waves.get_asteroid_count(wave)
		var speed := waves.get_speed_multiplier(wave)
		var composition := waves.get_composition(wave)
		var armored := composition.count(Asteroid.Variant.ARMORED)
		check(count >= previous_count, "wave %d has no fewer rocks than the last" % wave)
		check(speed >= previous_speed, "wave %d is no slower than the last" % wave)
		check(armored >= previous_armored or count < previous_count, "wave %d keeps its armored share" % wave)
		check_eq(composition.size(), count, "wave %d composition matches its count" % wave)
		previous_count = count
		previous_speed = speed
		previous_armored = armored


func test_ufo_plan_stays_within_limits() -> void:
	var ufos := GameManager.balance.ufos
	var previous_total := 0
	for wave in range(1, WAVES_CHECKED + 1):
		var plan := ufos.get_wave_plan(wave)
		check(plan.size() <= ufos.max_ufos_per_wave, "wave %d sends at most the max UFOs" % wave)
		check(plan.size() >= previous_total, "wave %d sends no fewer UFOs than the last" % wave)
		check(ufos.get_spawn_interval(wave) >= ufos.min_spawn_interval, "wave %d interval respects the floor" % wave)
		if wave < ufos.large_first_wave:
			check_eq(plan.size(), 0, "no UFOs before wave %d" % ufos.large_first_wave)
		if wave < ufos.small_first_wave:
			check(not plan.has(Ufo.Type.SMALL), "no small UFOs before wave %d" % ufos.small_first_wave)
		previous_total = plan.size()
