module slots::roll{
    // Error
    const EInvalidResultNumber: u64 = 1;

    //Roll number players
    const DEFAULT_MIN_RESULT_ROLL: u64=0;
    const DEFAULT_MAX_RESULT_ROLL: u64=9;

    const DEFAULT_ROLL_NUMBER_QUEEN: u64=0;
    
    const PLAYER_LOSE: u64=0;
    const PLAYER_WON: u64=1;
    
    const MULTIPLIER_ZERO: u64=0;
    const MULTIPLIER_ONE: u64=1;
    const MULTIPLIER_TWO: u64=2;
    const MULTIPLIER_THREE: u64=3;
    const MULTIPLIER_FIVE: u64=5;
    const MULTIPLIER_EIGHT: u64=8;

    const NUMBER_THREE: u64=3;
    const NUMBER_FIVE: u64=5;
    const NUMBER_EIGHT: u64=8;

    friend slots::slot_game;

    public(friend) fun validate_roll_players(
        result_roll_one: u64,
        result_roll_two: u64,
        result_roll_three: u64
    ){
        map_result_roll(result_roll_one);
        map_result_roll(result_roll_two);
        map_result_roll(result_roll_three);
    }

    public(friend) fun roll_player(
        result_roll_one: u64,
        result_roll_two: u64,
        result_roll_three: u64
    ): (u64, u64) {
        validate_roll_players(result_roll_one, result_roll_two, result_roll_three);

        if(result_roll_one == result_roll_two && result_roll_three==DEFAULT_ROLL_NUMBER_QUEEN){
            return (PLAYER_WON, MULTIPLIER_ONE)
        };

        if(result_roll_one == result_roll_three && result_roll_two==DEFAULT_ROLL_NUMBER_QUEEN){
            return (PLAYER_WON, MULTIPLIER_ONE)
        };

        if(result_roll_two == result_roll_three && result_roll_one==DEFAULT_ROLL_NUMBER_QUEEN){
            return (PLAYER_WON, MULTIPLIER_ONE)
        };

        if(result_roll_two == result_roll_three && result_roll_one==DEFAULT_ROLL_NUMBER_QUEEN){
            return (PLAYER_WON, MULTIPLIER_ONE)
        };

        if(result_roll_one == result_roll_two && result_roll_one==result_roll_three && result_roll_one==NUMBER_THREE){
            return (PLAYER_WON, MULTIPLIER_THREE)
        };

        if(result_roll_one == result_roll_two && result_roll_one==result_roll_three && result_roll_one==NUMBER_FIVE){
            return (PLAYER_WON, MULTIPLIER_FIVE)
        };

        if(result_roll_one == result_roll_two && result_roll_one==result_roll_three && result_roll_one==NUMBER_EIGHT){
            return (PLAYER_WON, MULTIPLIER_EIGHT)
        };

        return (PLAYER_LOSE, MULTIPLIER_ZERO)
    }

    fun map_result_roll(result_roll: u64){
        assert!(result_roll >= DEFAULT_MIN_RESULT_ROLL && result_roll <= DEFAULT_MAX_RESULT_ROLL, EInvalidResultNumber)
    }
}