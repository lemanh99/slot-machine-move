module slots::slot_game{
    use std::vector;
    use std::option::{Self, Option};
    use std::string::String;
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::bls12381::bls12381_min_pk_verify;
    use sui::hash::{blake2b256};
    use sui::dynamic_object_field as dof;

    use slots::events;
    use slots::house_data::{Self as hd, HouseData};
    // --------------- Contant ---------------
    // Error code

    const EInvalidStakeAmount: u64 = 0;
    const EInvalidResultNumber: u64 = 1;
    const EInvalidBlsSig: u64 = 2;
    const EBalanceNotEnough: u64 = 3;
    const EGameDoesNotExist: u64 = 4;
    
    const DEFAULT_MIN_RESULT_ROLL: U64=0;
    const DEFAULT_MAX_RESULT_ROLL: U64=12;

    // --------------- Objects ---------------

    struct SlotGame<phantom T> has key, store {
        id: UID,
        player: address,
        total_stake: Balance<T>,
        result_roll_one: u64,
        result_roll_two: u64,
        result_roll_three: u64,
        seed: vector<u8>,
    }

    /// Only a house can create games currently to ensure that we cannot be hacked
    public fun start_game<T> (
        result_roll_one: u64,
        result_roll_two: u64,
        result_roll_three: u64,
        seed: vector<u8>,
        house_data: &mut HouseData,
        coin: Coin<T>,
        ctx: &mut TxContext
    ): ID {
        let fee_rate = hd::fee_rate<T>(house_data);
        let game_id = new_game<T>(
            result_roll_one,
            result_roll_two,
            result_roll_three,
            seed,
            house_data,
            coin,
            ctx
        );
        game_id
    }

    public fun new_game<T>(
        result_roll_one: u64,
        result_roll_two: u64,
        result_roll_three: u64,
        seed: vector<u8>,
        house_data: &mut HouseData<T>,
        coin: Coin<T>,
        ctx: &mut TxContext
    ): ID {
        map_result_roll(result_roll_one);
        map_result_roll(result_roll_two);
        map_result_roll(result_roll_three);
        let user_stake_amount = coin::value(&coin);
        assert!(
            user_stake_amount>= hd::min_stake_amount<T>(house_data) && user_stake_amount>= hd::max_stake_amount<T>(house_data),
            EInvalidStakeAmount
        );

        let user_balance_stake = coin::into_balance(user_stake_amount);
        assert!(hd::balance(house_data) >= user_balance_stake, EPoolNotEnough);
        
        // Fund of house
        let house_stake = balance::split(&mut house_data.balance, user_stake_amount);
        balance::join(&mut user_balance_stake, house_stake);

        let game_uid = object::new(ctx);
        let player = tx_context::sender(ctx);

        let game = SlotGame<T>{
            id: game_uid,
            player,
            total_stake: house_stake,
            result_roll_one,
            result_roll_two,
            result_roll_three,
            seed
        };

        let game_id = object::uid_to_inner(&game_uid);
        events::emit_create_game<T>(
            game_id,
            player,
            user_stake_amount,
            result_roll_one,
            result_roll_two,
            result_roll_three
        );
        dof::add(&mut house_data.id, game_id, game);
        game_id //return game id
    }

    public fun finish_game<T>(
        game_id: ID, 
        house_data: &mut HouseData<T>, 
        bls_sig: vector<u8>, 
        ctx: &mut TxContext
    ){
        assert!(game_exists(house_data, game_id), EGameDoesNotExist);

        let SlotGame {
            id,
            player,
            total_stake,
            result_roll_one,
            result_roll_two,
            result_roll_three,
            seed
        } = dof::remove<ID, SlotGame<T>>(&mut house_data.id, game_id);
        
        let msg_vec = object::uid_to_bytes(&id);
        vector::append(&mut msg_vec, seed);
        let public_key = hd::public_key<T>(house_data);

        // Step 1: Check the BLS signature, if its invalid abort.
        let is_sig_valid = bls12381_min_pk_verify(&bls_sig, &public_key, &msg_vec);
        assert!(is_sig_valid, EInvalidBlsSig);
        object::delete(id);

        //  Hash the beacon before taking the 1st byte.
        let hashed_beacon = blake2b256(&bls_sig);
        let first_byte = *vector::borrow(&hashed_beacon, 0);
    }
    
    

    fun game_exists<T>(house_data: &mut HouseData<T>, game_id: ID): bool {
        dof::exists_with_type<ID, SlotGame<T>>(&house_data.id, game_id)
    }

    fun map_result_roll(result_roll: u64){
        assert!(result_roll >= DEFAULT_MIN_RESULT_ROLL && result_roll <= DEFAULT_MAX_RESULT_ROLL, EInvalidResultNumber)
    }
}