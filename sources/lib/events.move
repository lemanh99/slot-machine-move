module slots::events {
    // use std::option::{Self, Option};
    // use std::string::String;
    use sui::object::{ ID };
    // use sui::tx_context::{TxContext};
    use sui::event::emit;

    friend slots::house_data;
    friend slots::slot_game;

    // --------------------------Event House data---------------------------
    struct HouseDataDeposit<phantom T> has copy, store, drop {
        amount: u64
    }

    struct HouseDataWithdraw<phantom T> has copy, store, drop {
        amount: u64
    }

    // event emit deposit
    public(friend) fun emit_house_data_deposit<T>(amount: u64) {
        emit(HouseDataDeposit<T> {
            amount,
        });
    }

    // event emit withdraw
    public(friend) fun emit_house_data_withdraw<T>(amount: u64) {
        emit(HouseDataWithdraw<T>{
            amount,
        });
    }

    // --------------------------Event Slot Game ---------------------------
    struct GameCreated<phantom T> has copy, store, drop {
        game_id: ID,
        player: address,
        user_stake: u64,
        result_roll_one: u64,
        result_roll_two: u64,
        result_roll_three: u64,
    }

    public(friend) fun emit_create_game<T>(
        game_id: ID,
        player: address,
        user_stake: u64,
        result_roll_one: u64,
        result_roll_two: u64,
        result_roll_three: u64
    ){
        emit(GameCreated<T>{
            game_id,
            player,
            user_stake,
            result_roll_one,
            result_roll_two,
            result_roll_three
        })
    }

    struct FeeCollection<phantom T> has copy, store, drop{
        amount: u64
    }

    public(friend) fun emit_fee_collection<T>(amount: u64){
        emit(FeeCollection<T>{
            amount
        })
    }

    struct Outcome<phantom T> has copy, store, drop{
        game_id: ID,
        player: address,
        player_won: bool,
        stake_amount: u64,
        status: u8,
    }

    public(friend) fun emit_result<T>(
        game_id: ID,
        player: address,
        player_won: bool,
        stake_amount: u64,
        status: u8
    ){
        emit(Outcome<T>{
            game_id,
            player,
            player_won,
            stake_amount,
            status,
        })
    }
}