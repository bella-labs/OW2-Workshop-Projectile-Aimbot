settings {
    "main": {
        "description": "A demo for how to create a projectile aimbot.\nTries to solve for projectile gravity and delta vector, though it is inaccurate at very long and short ranges.",
        "modeName": "Projectile Aimbot Demo"
    },
    "gamemodes": {
        "skirmish": {
            "enabledMaps": [
                "workshopChamber"
            ]
        },
        "general": {
            "gamemodeStartTrigger": "immediately",
            "heroLimit": "off",
            "tankPassiveHealthBonus": "alwaysEnabled"
        }
    }
}

globalvar hero_array
globalvar hero_array_index
globalvar hero_proj_speed
globalvar hero_proj_gravity
globalvar hero_proj_delta

playervar curr_hero
playervar curr_hero_index
playervar proj_type
playervar proj_speed
playervar proj_gravity
playervar proj_delta
playervar proj_delta_xz
playervar look_target
playervar proj_calc_a
playervar proj_calc_b
playervar proj_calc_c
playervar proj_calc_d
playervar proj_calc_e
playervar proj_calc_t
playervar proj_calc_t1
playervar proj_calc_t2
playervar aim_spot

subroutine update_projectile_data
subroutine calc_proj_lead
subroutine calc_arc_proj_lead
subroutine solve_quartic
subroutine set_curr_hero_index


def set_curr_hero_index():
    @Name "SUB: set_curr_hero_index"

    eventPlayer.curr_hero = eventPlayer.getCurrentHero()
    eventPlayer.curr_hero_index = 0
    while(eventPlayer.curr_hero_index < len(hero_array) and eventPlayer.curr_hero != hero_array[eventPlayer.curr_hero_index]):
            eventPlayer.curr_hero_index += 1


def update_projectile_data():
    @Name "SUB: update_projectile_data"
    
    eventPlayer.proj_speed = hero_proj_speed[eventPlayer.curr_hero_index][eventPlayer.proj_type-1]
    eventPlayer.proj_gravity = hero_proj_gravity[eventPlayer.curr_hero_index][eventPlayer.proj_type-1]
    eventPlayer.proj_delta = hero_proj_delta[eventPlayer.curr_hero_index][eventPlayer.proj_type-1]


def set_proj_facing():
    @Name "SUB: set_proj_facing"

    update_projectile_data()
    eventPlayer.startFacing(directionTowards(eventPlayer.getEyePosition(), eventPlayer.aim_spot), 9999, Relativity.TO_WORLD, FacingReeval.DIRECTION_AND_TURN_RATE)


def calc_proj_lead():
    @Name "SUB: calc_proj_lead (KJRR5P)"

    eventPlayer.proj_delta_xz = eventPlayer.look_target.getEyePosition() - eventPlayer.getEyePosition()
    eventPlayer.proj_calc_a = dotProduct(eventPlayer.look_target.getVelocity(), eventPlayer.look_target.getVelocity()) - eventPlayer.proj_speed ** 2
    eventPlayer.proj_calc_b = -2 * dotProduct(eventPlayer.look_target.getVelocity(), eventPlayer.proj_delta_xz)
    eventPlayer.proj_calc_c = dotProduct(eventPlayer.proj_delta_xz, eventPlayer.proj_delta_xz)
    eventPlayer.proj_calc_d = eventPlayer.proj_calc_b * -1 / (2 * eventPlayer.proj_calc_a)
    eventPlayer.proj_calc_e = (sqrt(eventPlayer.proj_calc_b ** 2 - 4 * eventPlayer.proj_calc_a * eventPlayer.proj_calc_c)) / (2 * eventPlayer.proj_calc_a)
    eventPlayer.proj_calc_t1 = eventPlayer.proj_calc_d - eventPlayer.proj_calc_e
    eventPlayer.proj_calc_t2 = eventPlayer.proj_calc_d + eventPlayer.proj_calc_e
    if eventPlayer.proj_calc_t1 > eventPlayer.proj_calc_t2 and eventPlayer.proj_calc_t2 > 0:
        eventPlayer.proj_calc_t = eventPlayer.proj_calc_t2
    else:
        eventPlayer.proj_calc_t = eventPlayer.proj_calc_t1
    eventPlayer.aim_spot = eventPlayer.look_target.getEyePosition() + eventPlayer.look_target.getVelocity() * eventPlayer.proj_calc_t



def calc_arc_proj_lead():
    @Name "SUB: calc_arc_proj_lead (KJRR5P)"

    eventPlayer.proj_calc_a = eventPlayer.proj_speed ** 2 - dotProduct(eventPlayer.look_target.getVelocity(), eventPlayer.look_target.getVelocity())
    eventPlayer.proj_calc_b = dotProduct(eventPlayer.look_target.getVelocity(), eventPlayer.look_target.getEyePosition() - eventPlayer.getEyePosition())
    eventPlayer.proj_calc_c = dotProduct(eventPlayer.look_target.getEyePosition() - eventPlayer.getEyePosition(), eventPlayer.look_target.getEyePosition() - eventPlayer.getEyePosition())
    eventPlayer.proj_calc_d = eventPlayer.proj_calc_b ** 2 + eventPlayer.proj_calc_a * eventPlayer.proj_calc_c
    if eventPlayer.proj_calc_d >= 0:
        eventPlayer.proj_calc_t = (eventPlayer.proj_calc_b + sqrt(eventPlayer.proj_calc_d)) / eventPlayer.proj_calc_a
        if eventPlayer.proj_calc_t < 0:
            eventPlayer.proj_calc_t = 0
    eventPlayer.aim_spot = eventPlayer.look_target.getEyePosition() + eventPlayer.look_target.getVelocity() * eventPlayer.proj_calc_t + 0.5 * vect(0, (216*(eventPlayer.proj_gravity/9.84))/eventPlayer.proj_speed, 0) * eventPlayer.proj_calc_t ** 2
    # This doesn't accurately adjust for delta vector, it just kinda works for most distances, errors are really noticeable long range. It seems to overestimate at close range and underestimate at long range.
    if eventPlayer.proj_delta != 0:
        eventPlayer.proj_delta_xz = distance(eventPlayer.look_target.getEyePosition(), eventPlayer.getEyePosition())
        eventPlayer.aim_spot = eventPlayer.aim_spot - vect(0,eventPlayer.proj_delta*eventPlayer.proj_delta_xz,0)

rule "Initialize: Static Global Variables":

    hero_array_index = 0
    hero_array[hero_array_index] = Hero.DVA
    hero_proj_speed[hero_array_index] = [0,0,0,40,12]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    
    
    hero_array_index += 1
    hero_array[hero_array_index] = Hero.DOOMFIST
    hero_proj_speed[hero_array_index] = [80,44,0,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    
    
    hero_array_index += 1
    hero_array[hero_array_index] = Hero.JUNKER_QUEEN
    hero_proj_speed[hero_array_index] = [80,30,0,0,0]
    hero_proj_gravity[hero_array_index] = [0,9.84,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.ORISA
    hero_proj_speed[hero_array_index] = [90,70,0,0,0]
    hero_proj_gravity[hero_array_index] = [0,9.84,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    
    
    hero_array_index += 1
    hero_array[hero_array_index] = Hero.RAMATTRA
    hero_proj_speed[hero_array_index] = [80,0,0,30,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,9.84,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.REINHARDT
    hero_proj_speed[hero_array_index] = [0,0,0,25,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.ROADHOG
    hero_proj_speed[hero_array_index] = [80,80,40,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.SIGMA
    hero_proj_speed[hero_array_index] = [50,16.5,0,37.5,0]
    hero_proj_gravity[hero_array_index] = [5.95,0,0,18.35,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.WINSTON
    hero_proj_speed[hero_array_index] = [0,0,0,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.HAMMOND
    hero_proj_speed[hero_array_index] = [0,0,0,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.ZARYA
    hero_proj_speed[hero_array_index] = [0,25,0,0,25]
    hero_proj_gravity[hero_array_index] = [0,9.84,0,0,9.84]
    hero_proj_delta[hero_array_index] = [0,0.1,0,0,0.1]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.ASHE
    hero_proj_speed[hero_array_index] = [0,0,25,0,15]
    hero_proj_gravity[hero_array_index] = [0,0,8.03,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.BASTION
    hero_proj_speed[hero_array_index] = [0,40,0,0,0]
    hero_proj_gravity[hero_array_index] = [0,9.84,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.MCCREE
    hero_proj_speed[hero_array_index] = [0,20,0,0,0]
    hero_proj_gravity[hero_array_index] = [0,9.84,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.ECHO
    hero_proj_speed[hero_array_index] = [75,50,0,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.GENJI
    hero_proj_speed[hero_array_index] = [60,60,50,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.HANZO
    hero_proj_speed[hero_array_index] = [110,0,110,0,20]
    hero_proj_gravity[hero_array_index] = [9.84,0,9.84,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.JUNKRAT
    hero_proj_speed[hero_array_index] = [25,0,25,17,0]
    hero_proj_gravity[hero_array_index] = [12.35,0,20.30,20.20,0]
    hero_proj_delta[hero_array_index] = [0.075,0,0.09,0.095,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.MEI
    hero_proj_speed[hero_array_index] = [20,115,0,0,20]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,9.84]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.PHARAH
    hero_proj_speed[hero_array_index] = [35,0,0,60,45]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.REAPER
    hero_proj_speed[hero_array_index] = [0,0,0,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.SOJOURN
    hero_proj_speed[hero_array_index] = [160,0,0,30,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.SOLDIER
    hero_proj_speed[hero_array_index] = [0,50,0,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.SOMBRA
    hero_proj_speed[hero_array_index] = [0,0,0,25,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,20.20,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.SYMMETRA
    hero_proj_speed[hero_array_index] = [0,50,20,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.TORBJORN
    hero_proj_speed[hero_array_index] = [70,120,17,0,40]
    hero_proj_gravity[hero_array_index] = [9.84,0,20,0,30.05]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.TRACER
    hero_proj_speed[hero_array_index] = [0,0,0,0,15]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,30.80]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0.19]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.WIDOWMAKER
    hero_proj_speed[hero_array_index] = [0,0,0,20,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,9.84,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    
    
    hero_array_index += 1
    hero_array[hero_array_index] = Hero.ANA
    hero_proj_speed[hero_array_index] = [125,0,60,30,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,9.84,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.BAPTISTE
    hero_proj_speed[hero_array_index] = [0,60,0,60,0]
    hero_proj_gravity[hero_array_index] = [0,20.1,0,20.10,0]
    hero_proj_delta[hero_array_index] = [0,0.007,0,0,0.007]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.BRIGITTE
    hero_proj_speed[hero_array_index] = [0,0,80,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.ILLARI
    hero_proj_speed[hero_array_index] = [0,0,0,0,32.5]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.KIRIKO
    hero_proj_speed[hero_array_index] = [20,90,0,35,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,9.84,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.LIFEWEAVER
    hero_proj_speed[hero_array_index] = [0,70,40,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,9.84,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.LUCIO
    hero_proj_speed[hero_array_index] = [50,0,0,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.MERCY
    hero_proj_speed[hero_array_index] = [50,0,0,0,100]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.MOIRA
    hero_proj_speed[hero_array_index] = [0,0,20,0,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]
    

    hero_array_index += 1
    hero_array[hero_array_index] = Hero.ZENYATTA
    hero_proj_speed[hero_array_index] = [90,90,90,90,0]
    hero_proj_gravity[hero_array_index] = [0,0,0,0,0]
    hero_proj_delta[hero_array_index] = [0,0,0,0,0]



       
rule "Set player projectile data":
    @Event eachPlayer
    @Team 1
    @Condition eventPlayer.hasSpawned() == true

    set_curr_hero_index()   
    # Basically an enum. 1 = primary, 2 = secondary, 3 = ability_1, 4 = ability_2, 5 = ultimate. Set to the projectile you'd like to track.
    eventPlayer.proj_type = 1
    eventPlayer.look_target = eventPlayer.getPlayerClosestToReticle(Team.2)
    set_proj_facing()


rule "Calculate Player Projectile Trajectory":
    @Event eachPlayer
    @Team 1
    @Condition eventPlayer.isAlive()
    @Condition eventPlayer.proj_type != 0
    @Condition eventPlayer.proj_speed != 0

    if eventPlayer.proj_gravity == 0:
        calc_proj_lead()
    else:
        calc_arc_proj_lead()
    wait()
    if RULE_CONDITION:
        goto RULE_START


# don't copy past here, if you just want the aimbot code
rule "(don't copy this and beyond if just want aimbot code) visualize impact point":
    @Event eachPlayer
    @Team 1

    createBeam(eventPlayer, Beam.GRAPPLE, eventPlayer.aim_spot, eventPlayer.aim_spot + directionTowards(eventPlayer.aim_spot, eventPlayer.getEyePosition()) * (distance(eventPlayer.getEyePosition(), eventPlayer.aim_spot) / 2), Color.WHITE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(eventPlayer, Effect.SPHERE, Color.YELLOW, eventPlayer.aim_spot, 0.15, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)


rule "test bot: create test bot / make unkillable":

    createDummy(Hero.ANA, Team.2, -1, vect(0,0,0), vect(0,0,0))
    getPlayersInSlot(0, Team.2).setStatusEffect(null, Status.UNKILLABLE, 9999)



rule "test bot: movement":
    @Event eachPlayer
    @Team 2

    eventPlayer.startThrottleInDirection(Vector.LEFT, 1, Relativity.TO_PLAYER, Throttle.REPLACE_EXISTING, ThrottleReeval.DIRECTION_AND_MAGNITUDE)
    wait(7)
    eventPlayer.startThrottleInDirection(Vector.RIGHT, 1, Relativity.TO_PLAYER, Throttle.REPLACE_EXISTING, ThrottleReeval.DIRECTION_AND_MAGNITUDE)
    wait(7)
    if RULE_CONDITION:
        goto RULE_START


rule "show_server_load":

    hudSubheader(hostPlayer, "Load (Curr/Avg/Peak):  {0}  /  {1}  /  {2}".format(getServerLoad(),getAverageServerLoad(),getPeakServerLoad()), HudPosition.RIGHT, -0.9, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)

