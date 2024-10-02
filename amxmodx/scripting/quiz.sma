#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

// Didn't add another quiz type

#define VERSION "1.1"
#define TAG "[QUIZ]"

#define MAX_PLAYERS 32
#define DEFAULT_SPEED 250.0

#define QUIZ_DELAY_MAX 15.0
#define QUIZ_DELAY_MIN 10.0
#define ROUND_DELAY 5.0

#define QUIZ_HARD_TIME 15.0
#define QUIZ_MEDIUM_TIME 10.0
#define QUIZ_EASY_TIME 7.5

#define REWARD_MAX 6
#define REWARD_MIN 1

enum _:Cvars { 

    CVAR_QUIZTYPE,
    CVAR_RANDOMQUIZ,
    CVAR_QUIZTIME,
    CVAR_QUIZTIMEAUTO,
    CVAR_RANDOMREWARD,

    CVAR_HEALTH,
    CVAR_ARMOR,
    CVAR_SPEED,
    CVAR_SPEEDTIME,
    CVAR_GODEMODETIME,
    CVAR_NOCLIPTIME

}

enum _:TaskIds ( += 987123 ){

    TASKID_QUIZSTART,
    TASKID_QUIZTIMER

}

new g_iAnswer
new g_Cvars[ Cvars ]
new bool:g_bAnswered
new bool:g_bPlayerSpeed[ MAX_PLAYERS + 1 ]
new Array:g_divisorArray

public plugin_init(){

    register_plugin( "Quiz", VERSION, "RedSMURF" )

    g_Cvars[ CVAR_QUIZTYPE ] = register_cvar( "quiz_quiztype", "1" ) // 0 - Off || 1 2 3 4 5
    g_Cvars[ CVAR_RANDOMQUIZ ] = register_cvar( "quiz_randomquiz", "1" ) // 0 1
    g_Cvars[ CVAR_QUIZTIME ] = register_cvar( "quiz_quiztime", "15" ) // 15 by default 
    g_Cvars[ CVAR_QUIZTIMEAUTO ] = register_cvar( "quiz_quiztimeauto", "1" ) // 0 1
    g_Cvars[ CVAR_RANDOMREWARD ] = register_cvar( "quiz_randomreward", "0" ) // 0 1

    g_Cvars[ CVAR_HEALTH ] = register_cvar( "quiz_health", "25" )
    g_Cvars[ CVAR_ARMOR ] = register_cvar( "quiz_armor", "50" )
    g_Cvars[ CVAR_SPEED ] = register_cvar( "quiz_speed", "320" )
    g_Cvars[ CVAR_SPEEDTIME ] = register_cvar( "quiz_speedtimer", "15" )
    g_Cvars[ CVAR_GODEMODETIME ] = register_cvar( "quiz_godmode", "10" )
    g_Cvars[ CVAR_NOCLIPTIME ] = register_cvar( "quiz_noclip", "5" )

    register_concmd( "givereward", "giveReward" )

    register_event( "CurWeapon", "EvCurWeapon", "be", "1=1" )
    register_logevent( "EvRoundEnd", 2, "1=Round_End" )

    // Intial State
    new Float:fRandom = random_float( QUIZ_DELAY_MIN, QUIZ_DELAY_MAX )
    set_task( fRandom, "quizStart", TASKID_QUIZSTART )
    set_task( fRandom, "sayHandler" )

    g_divisorArray = ArrayCreate( 1 )
    g_bAnswered = true

}

public sayHandler(){

    register_clcmd( "say", "submitAnswer" )
    register_clcmd( "say_team", "submitAnswer" )

    return PLUGIN_HANDLED

}

public giveReward( id ){

    new szArg[ 32 ], iReward
    read_argv( 1, szArg, sizeof( szArg ) )
    iReward = read_argv_int( 2 )

    if ( iReward < REWARD_MIN || iReward > REWARD_MAX ){

        client_print_color( id, print_team_default, "^4%s ^1There's no such reward ", TAG )
        return PLUGIN_HANDLED

    }

    new iClient = cmd_target( id, szArg, CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE )

    if ( iClient )
        rewardPlayer( iClient, iReward )
    else 
        client_print_color( id, print_team_default, "^4%s ^1Couldn't find player ", TAG )   


    return PLUGIN_HANDLED

}

public EvCurWeapon( id ){

    if ( is_user_connected( id ) && is_user_alive( id ) ){

        if ( g_bPlayerSpeed[ id ] )
            set_pev( id, pev_maxspeed, get_pcvar_float( g_Cvars[ CVAR_SPEED ] ) )

    }

    return PLUGIN_CONTINUE
     
}

public quizStart(){

    if ( get_pcvar_num( g_Cvars[ CVAR_QUIZTYPE ] ) > 0 ){

        new iQuizType = get_pcvar_num( g_Cvars[ CVAR_RANDOMQUIZ ] ) ? 
        random_num( REWARD_MIN, REWARD_MAX ) : get_pcvar_num( g_Cvars[ CVAR_QUIZTYPE ] )

        client_print_color( 0, print_team_default, "^4%s ^1%s", TAG, quizGenerate( iQuizType ) )

        g_bAnswered = false
        set_task( get_pcvar_float( g_Cvars[ CVAR_QUIZTIME ] ), "quizTimer", TASKID_QUIZTIMER )

    }

    return PLUGIN_CONTINUE

}

public quizGenerate( iQuizType ){

    new szQuiz[ 32 ]

    switch( iQuizType ){

        case 2 : { // Medium

            new cOper[ 2 ]
            new iOper[ 3 ]

            cOper[ 0 ] = random_num( 0, 1 ) ? '+' : '-'
            cOper[ 1 ] = random_num( 0, 1 ) ? '+' : '-'

            iOper[ 0 ] = random_num( 69, 99 )
            iOper[ 1 ] = random_num( 39, 59 )
            iOper[ 2 ] = random_num( 9, 29 )

            formatex( szQuiz, sizeof ( szQuiz ), "%i %c %i %c %i", iOper[ 0 ], cOper[ 0 ], iOper[ 1 ], cOper[ 1 ], iOper[ 2 ] )

            if ( cOper[ 0 ] == '+' && cOper[ 1 ] == '+' )
                g_iAnswer = iOper[ 0 ] + iOper[ 1 ] + iOper[ 2 ]

            else if ( cOper[ 0 ] == '+' && cOper[1] == '-' )
                g_iAnswer = iOper[ 0 ] + iOper[ 1 ] - iOper[ 2 ]

            else if ( cOper[ 0 ] == '-' && cOper[ 1 ] == '+' )
                g_iAnswer = iOper[ 0 ] - iOper[ 1 ] + iOper[ 2 ]

            else 
                g_iAnswer = iOper[ 0 ] - iOper[ 1 ] - iOper[ 2 ]

            if ( get_pcvar_num( g_Cvars[ CVAR_QUIZTIMEAUTO ] ) == 1 )
                set_pcvar_float( g_Cvars[ CVAR_QUIZTIME ], QUIZ_MEDIUM_TIME )

        }

        case 3 : { // Easy

            new cOper
            new iOper[ 2 ]

            cOper = random_num( 0, 1 ) ? '*' : '/'

            iOper[ 0 ] = random_num( 9, 69 )

            if ( cOper == '/' ){

                while ( isPrime( iOper[ 0 ] ) )
                    iOper[ 0 ] = random_num( 9, 69 )

                iOper[ 1 ] = getDivisor( iOper[ 0 ] )

            }else 
                iOper[ 1 ] = random_num( 9, 19 )

            formatex( szQuiz, sizeof( szQuiz ), "%i %c %i", iOper[ 0 ], cOper, iOper[ 1 ] )

            if ( cOper == '*' )
                g_iAnswer = iOper[ 0 ] * iOper[ 1 ]

            else 
                g_iAnswer = iOper[ 0 ] / iOper[ 1 ]

            if ( get_pcvar_num( g_Cvars[ CVAR_QUIZTIMEAUTO ] ) == 1 )
                set_pcvar_float( g_Cvars[ CVAR_QUIZTIME ], QUIZ_EASY_TIME )

        }

        case 4 : { // Hard

            new cOper[ 2 ]
            new iOper[ 3 ]

            cOper[ 0 ] = random_num( 0, 1 ) ? '+' : '-'
            cOper[ 1 ] = random_num( 0, 1 ) ? '*' : '/'

            iOper[ 0 ] = random_num( 69, 99 )

            iOper[ 1 ] = random_num( 9, 69 )

            if ( cOper[ 1 ] == '/' ){

                while ( isPrime( iOper[ 1 ] ) )
                    iOper[ 1 ] = random_num( 9, 69 )

                iOper[ 2 ] = getDivisor( iOper[ 1 ] )

            }else 
                iOper[ 2 ] = random_num( 9, 19 )

            formatex( szQuiz, sizeof( szQuiz ), "%i %c %i %c %i", iOper[ 0 ], cOper[ 0 ], iOper[ 1 ], cOper[ 1 ], iOper[ 2 ] )

            if ( cOper[ 0 ] == '+' && cOper[ 1 ] == '*' )
                g_iAnswer = iOper[ 0 ] + iOper[ 1 ] * iOper[ 2 ]
                
            else if ( cOper[ 0 ] == '+' && cOper[ 1 ] == '/' )
                g_iAnswer = iOper[ 0 ] + iOper[ 1 ] / iOper[ 2 ]

            else if ( cOper[ 0 ] == '-' && cOper[ 1 ] == '*' )
                g_iAnswer = iOper[ 0 ] - iOper[ 1 ] * iOper[ 2 ]

            else 
                g_iAnswer = iOper[ 0 ] - iOper[ 1 ] / iOper[ 2 ]

            if ( get_pcvar_num( g_Cvars[ CVAR_QUIZTIMEAUTO ] ) == 1 )
                set_pcvar_float( g_Cvars[ CVAR_QUIZTIME ], QUIZ_HARD_TIME )

        }

        default : { // Easy

            new cOper
            new iOper[ 2 ]

            cOper = random_num( 0, 1 ) ? '+' : '-'

            iOper[ 0 ] = random_num( 69, 99 )
            iOper[ 1 ] = random_num( 9, 59 )

            formatex( szQuiz, sizeof( szQuiz ), "%i %c %i", iOper[ 0 ], cOper, iOper[ 1 ] )

            if ( cOper == '+' )
                g_iAnswer = iOper[ 0 ] + iOper[ 1 ]

            else 
                g_iAnswer = iOper[ 0 ] - iOper[ 1 ]

            if ( get_pcvar_num( g_Cvars[ CVAR_QUIZTIMEAUTO ] ) == 1 )
                set_pcvar_float( g_Cvars[ CVAR_QUIZTIME ], QUIZ_EASY_TIME )

        }
    }

    return szQuiz;

}

public submitAnswer( id ){

    // new szArg[ 8 ]
    // read_args( szArg, sizeof( szArg ) )
    // remove_quotes( szArg )

    // if ( !is_str_num( szArg ) ) return PLUGIN_CONTINUE

    new iArg = read_argv_int( 1 )

    if ( !g_bAnswered ){       

        if ( iArg == g_iAnswer ){

            g_bAnswered = true

            new szUserName[ 32 ]
            get_user_name( id, szUserName, sizeof( szUserName ) )
            client_print_color( 0, print_team_default, "^4%s ^1%s responds with the right answer : ^4%i", TAG, szUserName, g_iAnswer )

            remove_task( TASKID_QUIZTIMER ) // Flow stops 
            set_task( random_float( QUIZ_DELAY_MIN, QUIZ_DELAY_MAX ), "quizStart", TASKID_QUIZSTART )

            if ( get_pcvar_num( g_Cvars[ CVAR_RANDOMREWARD ] ) )
                rewardPlayer( id, random_num( REWARD_MIN, REWARD_MAX ) )

            else 
                showMenu( id )

        }

    }else if ( iArg == g_iAnswer ){

        client_print_color( id, print_team_default, "^4%s ^1The quiz has already been answered", TAG )

    }

    return PLUGIN_CONTINUE

}

public showMenu(id){

    new iMenu = menu_create( "\yChoose your reward ", "menuHandler" )
    new szItem[ 32 ]

    formatex( szItem, sizeof( szItem ), "\w+%i Health", get_pcvar_num( g_Cvars[ CVAR_HEALTH ] ) )
    menu_additem( iMenu, szItem )

    formatex( szItem, sizeof( szItem ), "\w+%i Armor", get_pcvar_num( g_Cvars[ CVAR_ARMOR ] ) )
    menu_additem( iMenu, szItem )

    formatex( szItem, sizeof( szItem ), "\w+%i Health +%i Armor", get_pcvar_num( g_Cvars[ CVAR_HEALTH ] ) - 10, floatround( get_pcvar_num( g_Cvars[ CVAR_ARMOR ] ) / 2.0 ) )
    menu_additem( iMenu, szItem )

    formatex( szItem, sizeof( szItem ), "\w%i seconds SuperSpeed", get_pcvar_num( g_Cvars[ CVAR_SPEEDTIME ] ) )
    menu_additem( iMenu, szItem )

    formatex( szItem, sizeof( szItem ), "\w%i seconds GodMode", get_pcvar_num( g_Cvars[ CVAR_GODEMODETIME ] ) )
    menu_additem( iMenu, szItem )

    formatex( szItem, sizeof( szItem ), "\w%i seconds NoClip", get_pcvar_num( g_Cvars[ CVAR_NOCLIPTIME ] ) )
    menu_additem( iMenu, szItem )

    menu_setprop( iMenu, MPROP_NUMBER_COLOR, "\y" )
    menu_setprop( iMenu, MPROP_EXIT, MEXIT_ALL )

    menu_display( id, iMenu )

}

public menuHandler( id, menu, item ){

    rewardPlayer( id, item + 1 ) // starts from 0

    menu_destroy( menu )

    return PLUGIN_HANDLED

}

public rewardPlayer( id, item ){

    new szName[ 32 ]
    get_user_name( id, szName, sizeof( szName ) )

    switch( item ){

        case 1 : {

            new Float:fHealth
            pev( id, pev_health, fHealth )

            fHealth += get_pcvar_float( g_Cvars[ CVAR_HEALTH ] )
            set_pev( id, pev_health, fHealth )

            client_print_color( 0, print_team_blue, "^4%s ^1%s recieved ^4+%i Health", TAG, szName, get_pcvar_num( g_Cvars[ CVAR_HEALTH ] ) )

        }

        case 2 : {

            new Float:fArmor
            pev( id, pev_armorvalue, fArmor )

            fArmor += get_pcvar_num( g_Cvars[ CVAR_ARMOR ] )
            set_pev( id, pev_armorvalue, fArmor )

            client_print_color( 0, print_team_blue, "^4%s ^1%s recieved ^3+%i Armor", TAG, szName, get_pcvar_num( g_Cvars[ CVAR_ARMOR ] ) )

        }

        case 3 : {

            new Float:fHealth, Float:fArmor
            pev( id, pev_health, fHealth )
            pev( id, pev_armorvalue, fArmor )

            fHealth += get_pcvar_float( g_Cvars[ CVAR_HEALTH ] )
            set_pev( id, pev_health, fHealth )

            fArmor += get_pcvar_num( g_Cvars[ CVAR_ARMOR ] )
            set_pev( id, pev_armorvalue, fArmor )

            client_print_color( 0, print_team_blue, "^4%s ^1%s recieved ^4+%i Health ^3+%i Armor", TAG, szName, get_pcvar_num( g_Cvars[ CVAR_HEALTH ] ) - 10, floatround( get_pcvar_num( g_Cvars[ CVAR_ARMOR ] ) / 2.0 ) )

        }

        case 4 : {

            g_bPlayerSpeed[ id ] = true

            EvCurWeapon( id )
            set_task( get_pcvar_float( g_Cvars[ CVAR_SPEEDTIME ] ), "removeSuperSpeed", id )

            client_print_color( 0, print_team_grey, "^4%s ^1%s recieved ^3Speed ^1for %i seconds", TAG, szName, get_pcvar_num( g_Cvars[ CVAR_SPEEDTIME ] ) )

        }

        case 5 : {

            // set_user_godmode( id, 1 )
            // set_task( get_pcvar_float( g_Cvars[ CVAR_GODEMODETIME ] ), "removeGodMode", id )
            set_pev( id, pev_takedamage, DAMAGE_NO )
            set_task( get_pcvar_float( g_Cvars[ CVAR_GODEMODETIME ] ), "removeGodMode", id )

            client_print_color( 0, print_team_grey, "^4%s ^1%s recieved ^3GodMode ^1for %i seconds",TAG, szName, get_pcvar_num( g_Cvars[ CVAR_GODEMODETIME ] ) )

        }

        case 6 : {

            set_pev( id, pev_movetype, MOVETYPE_NOCLIP )
            set_task( get_pcvar_float( g_Cvars[ CVAR_NOCLIPTIME ] ), "removeNoClip", id )

            client_print_color( 0, print_team_grey, "^4%s ^1%s recieved ^3NoClip ^1for %i seconds",TAG, szName, get_pcvar_num( g_Cvars[ CVAR_NOCLIPTIME ] ) )


        }
    }

    return PLUGIN_HANDLED

}

public quizTimer(){

        g_bAnswered = true
        set_task( random_float( QUIZ_DELAY_MIN, QUIZ_DELAY_MAX ), "quizStart", TASKID_QUIZSTART )

        client_print_color( 0, print_team_default, "^4%s ^1No one answered during the available time", TAG )
        client_print_color( 0, print_team_default, "^4%s ^1The answer is ^4%i", TAG, g_iAnswer )

}

public EvRoundEnd(){

    if ( !g_bAnswered ){

        g_bAnswered = true

        remove_task( TASKID_QUIZTIMER )
        set_task( random_float( QUIZ_DELAY_MIN, QUIZ_DELAY_MAX ) + ROUND_DELAY, "quizStart", TASKID_QUIZSTART )

        client_print_color( 0, print_team_default, "^4%s ^1No one answered during the available time", TAG )
        client_print_color( 0, print_team_default, "^4%s ^1The answer is ^4%i", TAG, g_iAnswer )

    }else {

        remove_task( TASKID_QUIZSTART )
        set_task( random_float( QUIZ_DELAY_MIN, QUIZ_DELAY_MAX ) + ROUND_DELAY, "quizStart", TASKID_QUIZSTART )

    }

    return PLUGIN_CONTINUE

}

public isPrime( iNum ){

    if ( iNum != 1 ) {

        for ( new i = 2; i <= iNum / 2; i ++ ){

            if ( iNum % i == 0 )
                return false

        }

    }

    return true

}

public getDivisor( iNum ){

    new iDivisor = 1

    for ( new i = 3; i <= iNum / 2; i ++ ){

        if ( iNum % i == 0 )
            ArrayPushCell( g_divisorArray, i )

    }

    iDivisor = ArrayGetCell( g_divisorArray, random_num( 0, ArraySize( g_divisorArray ) - 1 ) )
    ArrayClear( g_divisorArray )

    return iDivisor

}

public removeSuperSpeed( id ){

    g_bPlayerSpeed[ id ] = false
    set_pev( id, pev_maxspeed, DEFAULT_SPEED )

    client_print_color( id, print_team_default, "^4%s ^1TIMES UP, your speed has been set back to normal", TAG )

}

public removeGodMode( id ){

    set_pev( id, pev_takedamage, DAMAGE_AIM )

    client_print_color( id, print_team_default, "^4%s ^1TIMES UP, You no longer have Godmode", TAG )

}

public removeNoClip( id ){

    set_pev( id, pev_movetype, MOVETYPE_WALK )

    client_print_color( id, print_team_default, "^4%s ^1TIMES UP, You no longer have NoClip", TAG )

}

public plugin_end(){

    ArrayDestroy( g_divisorArray )

}

