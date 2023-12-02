module slots::roll{
    use std::vector;
    // Error
    const EInvalidResultNumber: u64 = 0;
    const EInvalidLengthRollNumber: u64 = 1;

    const LENGHT_ROLL_NUMBER: u64=3;

    //Roll number players
    const DEFAULT_MIN_RESULT_ROLL: u8=0;
    const DEFAULT_MAX_RESULT_ROLL: u8=9;

    const DEFAULT_ROLL_NUMBER_QUEEN: u8=0;
    
    const PLAYER_LOSE: u8=0;
    const PLAYER_WON: u8=1;
    
    const MULTIPLIER_ZERO: u8=0;
    const MULTIPLIER_ONE: u8=1;
    // const MULTIPLIER_TWO: u64=2;
    const MULTIPLIER_THREE: u8=3;
    const MULTIPLIER_FIVE: u8=5;
    const MULTIPLIER_EIGHT: u8=8;

    const NUMBER_THREE: u8=3;
    const NUMBER_FIVE: u8=5;
    const NUMBER_EIGHT: u8=8;

    friend slots::slot_game;

    public(friend) fun validate_roll_players(
        roll_guess: vector<u8>,
    ): (u8, u8, u8){
        assert!(vector::length(&roll_guess) == LENGHT_ROLL_NUMBER, EInvalidLengthRollNumber);
        let result_roll_one= vector::pop_back(&mut roll_guess);
        let result_roll_two= vector::pop_back(&mut roll_guess);
        let result_roll_three= vector::pop_back(&mut roll_guess);
        map_result_roll(result_roll_one);
        map_result_roll(result_roll_two);
        map_result_roll(result_roll_three);
        return (result_roll_one, result_roll_two, result_roll_three)
    }

    public fun roll_player(
        roll_guess: vector<u8>,
    ): (u8, u8) {
        let (result_roll_one, result_roll_two, result_roll_three) = validate_roll_players(roll_guess);

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

    fun map_result_roll(result_roll: u8){
        assert!(result_roll >= DEFAULT_MIN_RESULT_ROLL && result_roll <= DEFAULT_MAX_RESULT_ROLL, EInvalidResultNumber)
    }
}