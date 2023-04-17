settings {
    "main": {
        "description": "A demo for how to create a projectile aim bot\nAssumes projectile has no arc\n Assumes projectile has no delta vector\nsee workshop.codes/wiki/articles/projectile+data+table for more info.\n also has a cubic and quartic equation solver for some reason.",
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

# cubic_root vars
globalvar cubic_root_in
globalvar cubic_root_out

# solve_quadric vars
globalvar quadric_in
globalvar quadric_out
globalvar quadric_var

# solve_cubic vars
globalvar cubic_in
globalvar cubic_out
globalvar cubic_var

# solve_quartic vars
globalvar quartic_in
globalvar quartic_out
globalvar quartic_var

# ballistic solver vars
globalvar impact_point
globalvar target_vel
globalvar target_vel_xz
globalvar target_pos
globalvar player_pos
globalvar diff_xz
globalvar ball_c0
globalvar ball_c1
globalvar ball_c2
globalvar ball_t
globalvar ball_speed

# Player vars
playervar proj_type
playervar curr_hero

subroutine get_cubic_root
subroutine solve_quadric
subroutine solve_cubic
subroutine solve_quartic


rule "show_server_load":

    hudSubheader(hostPlayer, "Load (Curr/Avg/Peak):  {0}  /  {1}  /  {2}".format(getServerLoad(),getAverageServerLoad(),getPeakServerLoad()), HudPosition.RIGHT, -0.9, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)


rule "initialize variables":
    #disableInspector()
    # initialize cubic root vars 
    cubic_root_in = null
    cubic_root_out = null
    # initialize quadric vars
    quadric_in = [null, null, null, null]
    quadric_out = [null, null, null]
    quadric_var = [null, null, null, null]

    # initialize cubic vars
    cubic_in = [null, null, null, null]
    cubic_out = [null, null, null, null]
    cubic_var = [null, null, null, null, null,
                 null, null, null, null, null,
                 null, null, null, null]

    # initialize quartic vars
    quartic_in = [null, null, null, null, null]
    quartic_out = [null, null, null, null, null]
    quartic_var = [null, null, null, null, null,
                   null, null, null, null, null,
                   null, null, null, null, null,
                   null]


       

def solve_quadric():
    @Name "sub: solve_quadric"

    quadric_out[1] = "nan"
    quadric_out[2] = "nan"

    #/* normal form: x^2 + px + q = 0 */
    # var p
    quadric_var[0] = quadric_in[1] / (2*quadric_in[0])
    # var q
    quadric_var[1] = quadric_in[2] / quadric_in[0]
    # var D
    quadric_var[2] = quadric_var[0] ** 2 - quadric_var[1]

    if quadric_var[2] == 0:
        quadric_out[1] = -quadric_var[0]
        quadric_out[0] = 1
        return
    elif quadric_var[2] < 0:
        quadric_out[0] = 0
        return
    else:
        quadric_var[3] = sqrt(quadric_var[2])
        quadric_out[1] = quadric_var[3] - quadric_var[0]
        quadric_out[2] = -quadric_var[3] - quadric_var[0]
        quadric_out[0] = 2


def solve_ballistic_arc():
    @Name "SUB: solve_ballistic_arc"

    impact_point = vect(0,0,0)

    target_vel_xz = vect(target_vel.x, 0, target_vel.z)
    diff_xz = vect(target_pos.x - player_pos.x, 0, target_pos.z - player_pos.z)

    ball_c0 = dotProduct(target_vel_xz, target_vel_xz) - ball_speed ** 2
    ball_c1 = 2 * dotProduct(diff_xz, target_vel_xz)
    ball_c2 = dotProduct(diff_xz, diff_xz)

    quadric_in = [ball_c0, ball_c1, ball_c2]
    solve_quadric()
    if quadric_out[2] > quadric_out[1] and quadric_out[2] > 0:
        ball_t = quadric_out[2]
    else:
        ball_t = quadric_out[1]

    impact_point = target_pos + (target_vel*ball_t)



rule "loop solve_ballistic_arc":
    @Event eachPlayer
    @Team 1

    target_vel = eventPlayer.getPlayerClosestToReticle(Team.2).getVelocity()
    target_pos = eventPlayer.getPlayerClosestToReticle(Team.2).getEyePosition()
    player_pos = eventPlayer.getEyePosition()
    solve_ballistic_arc()
    wait()

    if RULE_CONDITION:
        goto RULE_START


rule "set player facing impact point (aimbot)":
    @Event eachPlayer
    @Team 1

    eventPlayer.startFacing(directionTowards(eventPlayer.getEyePosition(), impact_point), 10000, Relativity.TO_WORLD, FacingReeval.DIRECTION_AND_TURN_RATE)

rule "set projectile type (change here for different abilities)":
    @Event eachPlayer
    @Team 1
    @Condition eventPlayer.hasSpawned()

    wait(1)
    eventPlayer.proj_type = "primary"


rule "set projectile speed - primary":
    @Event eachPlayer
    @Condition eventPlayer.proj_type == "primary"

    eventPlayer.curr_hero = eventPlayer.getCurrentHero()

    if eventPlayer.curr_hero == Hero.DOOMFIST:
        ball_speed = 80
    elif eventPlayer.curr_hero == Hero.DVA:
        ball_speed = 50
    elif eventPlayer.curr_hero == Hero.ORISA:
        ball_speed = 90
    elif eventPlayer.curr_hero == Hero.RAMATTRA:
        ball_speed = 80
    elif eventPlayer.curr_hero == Hero.ROADHOG:
        ball_speed = 80
    elif eventPlayer.curr_hero == Hero.SIGMA:
        ball_speed = 50
    elif eventPlayer.curr_hero == Hero.ECHO:
        ball_speed = 75
    elif eventPlayer.curr_hero == Hero.GENJI:
        ball_speed = 60
    elif eventPlayer.curr_hero == Hero.HANZO:
        ball_speed = 110
    elif eventPlayer.curr_hero == Hero.JUNKRAT:
        ball_speed = 25
    elif eventPlayer.curr_hero == Hero.MEI:
        ball_speed = 20
    elif eventPlayer.curr_hero == Hero.PHARAH:
        ball_speed = 35
    elif eventPlayer.curr_hero == Hero.SOJOURN:
        ball_speed = 160
    elif eventPlayer.curr_hero == Hero.TORBJORN:
        ball_speed = 70
    elif eventPlayer.curr_hero == Hero.ANA:
        ball_speed = 125
    elif eventPlayer.curr_hero == Hero.KIRIKO:
        ball_speed = 20
    elif eventPlayer.curr_hero == Hero.LIFEWEAVER:
        ball_speed = 70
    elif eventPlayer.curr_hero == Hero.LUCIO:
        ball_speed = 50
    elif eventPlayer.curr_hero == Hero.MERCY:
        ball_speed = 50
    elif eventPlayer.curr_hero == Hero.ZENYATTA:
        ball_speed = 90
    else:
        ball_speed = 0


rule "set projectile speed - secondary":
    @Event eachPlayer
    @Condition eventPlayer.proj_type == "secondary"

    eventPlayer.curr_hero = eventPlayer.getCurrentHero()

    if eventPlayer.curr_hero == Hero.DOOMFIST:
        ball_speed = 44
    elif eventPlayer.curr_hero == Hero.JUNKER_QUEEN:
        ball_speed = 30
    elif eventPlayer.curr_hero == Hero.ORISA:
        ball_speed = 70
    elif eventPlayer.curr_hero == Hero.ROADHOG:
        ball_speed = 80
    elif eventPlayer.curr_hero == Hero.SIGMA:
        ball_speed = 16.5
    elif eventPlayer.curr_hero == Hero.ZARYA:
        ball_speed = 25
    elif eventPlayer.curr_hero == Hero.BASTION:
        ball_speed = 40
    elif eventPlayer.curr_hero == Hero.ECHO:
        ball_speed = 50
    elif eventPlayer.curr_hero == Hero.GENJI:
        ball_speed = 60
    elif eventPlayer.curr_hero == Hero.TORBJORN:
        ball_speed = 120
    elif eventPlayer.curr_hero == Hero.MEI:
        ball_speed = 115
    elif eventPlayer.curr_hero == Hero.SOLDIER:
        ball_speed = 50
    elif eventPlayer.curr_hero == Hero.SYMMETRA:
        ball_speed = 50
    elif eventPlayer.curr_hero == Hero.BAPTISTE:
        ball_speed = 60
    elif eventPlayer.curr_hero == Hero.LIFEWEAVER:
        ball_speed = 40
    elif eventPlayer.curr_hero == Hero.KIRIKO:
        ball_speed = 90
    elif eventPlayer.curr_hero == Hero.ZENYATTA:
        ball_speed = 90
    else:
        ball_speed = 0


rule "set projectile speed - ability 1":
    @Event eachPlayer
    @Condition eventPlayer.proj_type == "ability 1"

    eventPlayer.curr_hero = eventPlayer.getCurrentHero()

    if eventPlayer.curr_hero == Hero.ROADHOG:
        ball_speed = 40
    elif eventPlayer.curr_hero == Hero.GENJI:
        ball_speed = 50
    elif eventPlayer.curr_hero == Hero.JUNKRAT:
        ball_speed = 25   
    elif eventPlayer.curr_hero == Hero.SYMMETRA:
        ball_speed = 20
    elif eventPlayer.curr_hero == Hero.TORBJORN:
        ball_speed = 17   
    elif eventPlayer.curr_hero == Hero.ANA:
        ball_speed = 60   
    elif eventPlayer.curr_hero == Hero.BRIGITTE:
        ball_speed = 80   
    elif eventPlayer.curr_hero == Hero.ZENYATTA:
        ball_speed = 90
    else:
        ball_speed = 0


rule "set projectile speed - ability 2":
    @Event eachPlayer
    @Condition eventPlayer.proj_type == "ability 2"

    eventPlayer.curr_hero = eventPlayer.getCurrentHero()

    if eventPlayer.curr_hero == Hero.DVA:
        ball_speed = 40
    elif eventPlayer.curr_hero == Hero.RAMATTRA:
        ball_speed = 30
    elif eventPlayer.curr_hero == Hero.REINHARDT:
        ball_speed = 25
    elif eventPlayer.curr_hero == Hero.SIGMA:
        ball_speed = 37.5
    elif eventPlayer.curr_hero == Hero.ASHE:
        ball_speed = 25
    elif eventPlayer.curr_hero == Hero.MCCREE:
        ball_speed = 20
    elif eventPlayer.curr_hero == Hero.HANZO:
        ball_speed = 110
    elif eventPlayer.curr_hero == Hero.JUNKRAT:
        ball_speed = 17
    elif eventPlayer.curr_hero == Hero.PHARAH:
        ball_speed = 60
    elif eventPlayer.curr_hero == Hero.SOJOURN:
        ball_speed = 30
    elif eventPlayer.curr_hero == Hero.SOMBRA:
        ball_speed = 25
    elif eventPlayer.curr_hero == Hero.TORBJORN:
        ball_speed = 40
    elif eventPlayer.curr_hero == Hero.WIDOWMAKER:
        ball_speed = 20
    elif eventPlayer.curr_hero == Hero.ANA:
        ball_speed = 30
    elif eventPlayer.curr_hero == Hero.BAPTISTE:
        ball_speed = 60
    elif eventPlayer.curr_hero == Hero.KIRIKO:
        ball_speed = 35
    elif eventPlayer.curr_hero == Hero.MOIRA:
        ball_speed = 20
    elif eventPlayer.curr_hero == Hero.ZENYATTA:
        ball_speed = 90
    else:
        ball_speed = 0

rule "set projectile speed - ultimate":
    @Event eachPlayer
    @Condition eventPlayer.proj_type == "ultimate"

    eventPlayer.curr_hero = eventPlayer.getCurrentHero()

    if eventPlayer.curr_hero == Hero.DVA:
        ball_speed = 12
    elif eventPlayer.curr_hero == Hero.ZARYA:
        ball_speed = 25
    elif eventPlayer.curr_hero == Hero.ASHE:
        ball_speed = 15
    elif eventPlayer.curr_hero == Hero.HANZO:
        ball_speed = 20
    elif eventPlayer.curr_hero == Hero.MEI:
        ball_speed = 20
    elif eventPlayer.curr_hero == Hero.PHARAH:
        ball_speed = 45
    elif eventPlayer.curr_hero == Hero.TORBJORN:
        ball_speed = 40
    elif eventPlayer.curr_hero == Hero.TRACER:
        ball_speed = 15
    elif eventPlayer.curr_hero == Hero.MERCY:
        ball_speed = 100
    else:
        ball_speed = 0
# don't copy past here, if you just want the aimbot code
rule "(don't copy this and beyond if just want aimbot code) visualize impact point":
    @Event eachPlayer
    @Team 1

    createBeam(eventPlayer, Beam.GRAPPLE, impact_point, impact_point + directionTowards(impact_point, eventPlayer.getEyePosition()) * (distance(eventPlayer.getEyePosition(), impact_point) / 2), Color.WHITE, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(eventPlayer, Effect.SPHERE, Color.YELLOW, impact_point, 0.15, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)

rule "test bot: create test bot ":

    createDummy(Hero.ANA, Team.2, -1, vect(0,0,0), vect(0,0,0))


rule "test bot: movement":
    @Event eachPlayer
    @Team 2

    eventPlayer.startThrottleInDirection(Vector.LEFT, 1, Relativity.TO_PLAYER, Throttle.REPLACE_EXISTING, ThrottleReeval.DIRECTION_AND_MAGNITUDE)
    wait(7)
    eventPlayer.startThrottleInDirection(Vector.RIGHT, 1, Relativity.TO_PLAYER, Throttle.REPLACE_EXISTING, ThrottleReeval.DIRECTION_AND_MAGNITUDE)
    wait(7)
    if RULE_CONDITION:
        goto RULE_START


def solve_cubic():
    @Name "sub: solve_cubic (not used)"

    cubic_out[1] = "nan"
    cubic_out[2] = "nan"
    cubic_out[3] = "nan"

    # variable translation
    # A      | cubic_var[0]
    # B      | cubic_var[1]
    # C      | cubic_var[2]
    # sq_A   | cubic_var[3]
    # p      | cubic_var[4]
    # q      | cubic_var[5]
    # cb_p   | cubic_var[6]
    # D      | cubic_var[7]
    # u      | cubic_var[8]
    # phi    | cubic_var[9]
    # t      | cubic_var[10]
    # sqrt_D | cubic_var[11]
    # v      | cubic_var[12]
    # sub    | cubic_var[13]

    #/* normal form: x^3 + Ax^2 + Bx + C = 0 */
    # var A
    cubic_var[0] = cubic_in[1] / cubic_in[0]
    # var B
    cubic_var[1] = cubic_in[2] / cubic_in[0]
    # var C
    cubic_var[2] = cubic_in[3] / cubic_in[0]

    # sq_A
    cubic_var[3] = cubic_var[0] ** 2
    # p
    cubic_var[4] = 1/3 * (-1/3 * cubic_var[3] + cubic_var[1])
    # q
    cubic_var[5] = 1/2 * (2/27 * cubic_var[0] * cubic_var[3] - 1/3 * cubic_var[0] * cubic_var[1] + cubic_var[2])
    #/* use Cardano's formula */
    # cb_p
    cubic_var[6] = cubic_var[4] ** 3
    # D
    cubic_var[7] = cubic_var[5] ** 2 + cubic_var[6]

    if cubic_var[7] == 0:
        if cubic_var[5] == 0:
            #/* one triple solution */
            cubic_out[1] = 0
            cubic_out[0] = 1
        else:
            #/* one single and one double solution */
            cubic_root_in = -cubic_var[5]
            get_cubic_root()
            # u
            cubic_var[8] = cubic_root_out
    elif cubic_var[7] < 0:
        #/* Casus irreducibilis: three real solutions */
        # phi
        cubic_var[9] = 1/3 * acos(-cubic_var[7] / sqrt(-cubic_var[8]))
        # t
        cubic_var[10] = 2 * sqrt(-cubic_var[6])

        cubic_out[1] = cubic_var[10] * cos(cubic_var[9])
        cubic_out[2] = -cubic_var[10] * cos(cubic_var[9] + 3.14159 / 3)
        cubic_out[2] = -cubic_var[10] * cos(cubic_var[9] - 3.14159 / 3)
        cubic_out[0] = 3
    else:
        #/* one real solution */
        # sqrt_D
        cubic_var[11] = sqrt(cubic_var[7])
        cubic_root_in = cubic_var[11] - cubic_var[5]
        get_cubic_root()
        # u
        cubic_var[8] = cubic_root_out
        cubic_root_in = cubic_var[11] + cubic_var[5]
        get_cubic_root()
        # v
        cubic_var[12] = cubic_root_out

        cubic_out[1] = cubic_var[8] + cubic_var[12]
        cubic_out[0] = 1

    #/* resubstitute */    
    # sub
    cubic_var[13] = 1/3 * cubic_var[0]

    if cubic_out[0] > 0:
        cubic_out[1] -= cubic_var[13]
    if cubic_out[0] > 1:
        cubic_out[2] -= cubic_var[13]
    if cubic_out[0] > 2:
        cubic_out[3] -= cubic_var[13]




def solve_quartic():
    @Name "sub: solve_quartic (not used)"

    quartic_out[1] = "nan"
    quartic_out[2] = "nan"
    quartic_out[3] = "nan"
    quartic_out[4] = "nan"

    # variable translation
    # coeffs[0] | quartic_var[0]
    # coeffs[1] | quartic_var[1]
    # coeffs[2] | quartic_var[2]
    # coeffs[3] | quartic_var[3]
    # z         | quartic_var[4]
    # u         | quartic_var[5]
    # v         | quartic_var[6]
    # sub       | quartic_var[7]
    # A         | quartic_var[8]
    # B         | quartic_var[9]
    # C         | quartic_var[10]
    # D         | quartic_var[11]
    # sq_A      | quartic_var[12]
    # p         | quartic_var[13]
    # q         | quartic_var[14]
    # r         | quartic_var[15]

    #/* normal form: x^4 + Ax^3 + Bx^2 + Cx + D = 0 */
    # var A
    quartic_var[8] = quartic_in[1] / quartic_in[0]
    # var B
    quartic_var[9] = quartic_in[2] / quartic_in[0]
    # var C
    quartic_var[10] = quartic_in[3] / quartic_in[0]
    # var D
    quartic_var[11] = quartic_in[4] / quartic_in[0]

    #/*  substitute x = y - A/4 to eliminate cubic term: x^4 + px^2 + qx + r = 0 */
    # var sq_A
    quartic_var[12] = quartic_var[8] ** 2
    # var p
    quartic_var[13] = -3/8 * quartic_var[12] + quartic_var[9]
    # var q
    quartic_var[14] = 1/8 * quartic_var[12] * quartic_var[8] - 1/2 * quartic_var[8] * quartic_var[9] + quartic_var[10]
    # var r
    quartic_var[15] = - 3/256 * quartic_var[12] * quartic_var[12] + 1/16 * quartic_var[12] * quartic_var[9] - 1/4 * quartic_var[8] * quartic_var[10] + quartic_var[11]

    if quartic_var[15] == 0:
        #/* no absolute term: y(y^3 + py + q) = 0 */

        # var coeffs[3]
        quartic_var[3] = quartic_var[14]
        # var coeffs[2]
        quartic_var[2] = quartic_var[13]
        # var coeffs[1]
        quartic_var[1] = 0
        # var coeffs[0]
        quartic_var[0] = 1

        cubic_in = [quartic_var[0], quartic_var[1], quartic_var[2], quartic_var[3]]
        solve_cubic()
        quartic_out[0] = cubic_out[0]
        quartic_out[1] = cubic_out[1]
        quartic_out[2] = cubic_out[2]
        quartic_out[3] = cubic_out[3]
    else:
        #/* solve the resolvent cubic ... */

        # var coeffs[3]
        quartic_var[3] = 1/2 * quartic_var[15] * quartic_var[13] - 1/8 * quartic_var[14] * quartic_var[14]
        # var coeffs[2]
        quartic_var[2] = -quartic_var[15]
        # var coeffs[1]
        quartic_var[1] = -1/2 * quartic_var[13]
        # var coeffs[0]
        quartic_var[0] = 1

        cubic_in = [quartic_var[0], quartic_var[1], quartic_var[2], quartic_var[3]]
        solve_cubic()
        quartic_out[1] = cubic_out[1]
        quartic_out[2] = cubic_out[2]
        quartic_out[3] = cubic_out[3]

        #/* ... and take the one real solution ... */
        # var z
        quartic_var[4] = cubic_out[1]
        #/* ... to build two quadric equations */
        # var u
        quartic_var[5] = quartic_var[4] * quartic_var[4] - quartic_var[15]
        # var v
        quartic_var[6] = 2 * quartic_var[4] - quartic_var[13]

        if quartic_var[5] == 0:
            quartic_var[5] = 0
        elif quartic_var[5] > 0:
            quartic_var[5] = sqrt(quartic_var[5])
        else:
            quadric_out[0] = 0
            return
        
        if quartic_var[6] == 0:
            quartic_var[6] = 0
        elif quartic_var[6] > 0:
            quartic_var[6] = sqrt(quartic_var[6])
        else:
            quadric_out[0] = 0
            return

        quartic_var[2] = quartic_var[4] - quartic_var[5]
        if quartic_var[13] < 0:
            quartic_var[1] = quartic_var[6]
        else:
            quartic_var[1] = -quartic_var[6]
        quartic_var[0] = 1
        
        quadric_in = [quartic_var[0], quartic_var[1], quartic_var[2]]
        solve_quadric()
        quartic_out[0] = quadric_out[0]

        quartic_var[2] = quartic_var[4] + quartic_var[5]
        if quartic_var[13] < 0:
            quartic_var[1] = -quartic_var[6]
        else:
            quartic_var[1] = quartic_var[6]
        quartic_var[0] = 1

        if quartic_out[0] == 0:
            quadric_in = [quartic_var[0], quartic_var[1], quartic_var[2]]
            solve_quadric()
            quartic_out[0] += quadric_out[0]
            quartic_out[1] = quadric_out[1]
            quartic_out[2] = quadric_out[2]
        elif quartic_out[0] == 1:
            quadric_in = [quartic_var[0], quartic_var[1], quartic_var[2]]
            solve_quadric()
            quartic_out[0] += quadric_out[0]
            quartic_out[2] = quadric_out[2]
            quartic_out[3] = quadric_out[3]
        elif quartic_out[0] == 2:
            quadric_in = [quartic_var[0], quartic_var[1], quartic_var[2]]
            solve_quadric()
            quartic_out[0] += quadric_out[0]
            quartic_out[3] = quadric_out[3]
            quartic_out[4] = quadric_out[4]
    
    quartic_var[7] = 1/4 * quartic_var[8]

    if quartic_out[0] > 0:
        quartic_out[1] -= quartic_var[7]
    if quartic_out[0] > 1:
        quartic_out[2] -= quartic_var[7]
    if quartic_out[0] > 2:
        quartic_out[3] -= quartic_var[7]
    if quartic_out[0] > 3:
        quartic_out[4] -= quartic_var[7]

def get_cubic_root():
    @Name "sub: get_cubic_root (not used)"

    if cubic_root_in > 0:
        cubic_root_out = cubic_root_in ** (1/3)
    elif cubic_root_in < 0:
        cubic_root_out = -(-cubic_root_in ** (1/3))
    else:
        cubic_root_out = 0