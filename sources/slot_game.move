module slots::slot{
    use std::vector;
    use std::option::{Self, Option};
    use std::string::String;
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};

    // --------------- Objects ---------------

    struct SlotGame<phantom T> has key, store {
        id: UID,
        player: address,
        total_stake: Balance<T>,
        result_roll_one: u64,
        result_roll_two: u64,
        result_roll_three: u64,
    }

    public fun start_game<T> (
        
    ){

    }
}