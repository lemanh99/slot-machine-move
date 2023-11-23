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
    use sui::transfer::{Self};

    use slots::events;
    use slots::roll;
    use slots::house_data::{Self as hd, HouseData};
    // --------------- Contant ---------------
    // Error code

    const EInvalidStakeAmount: u64 = 0;
    const EInvalidBlsSig: u64 = 2;
    const EBalanceNotEnough: u64 = 3;
    const EGameDoesNotExist: u64 = 4;
    const EPoolNotEnough: u64 = 5;

    // -----------
    const GAME_RETURN: u8 = 2;
    const FEE_PRECISION: u128 = 100;

    // --------------- Objects ---------------

    struct SlotGame<phantom T> has key, store {
        id: UID,
        player: address,
        total_stake: Balance<T>,
        fee_rate: u128,
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
        house_data: &mut HouseData<T>,
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
        roll::validate_roll_players(result_roll_one, result_roll_two, result_roll_three);
        let user_stake_amount = coin::value(&coin);
        assert!(
            user_stake_amount>= hd::min_stake_amount<T>(house_data) && user_stake_amount>= hd::max_stake_amount<T>(house_data),
            EInvalidStakeAmount
        );

        assert!(hd::balance(house_data) >= user_stake_amount, EPoolNotEnough);
        
        // Fund of house
        let user_balance_stake = coin::into_balance(coin);
        let house_stake = balance::split(hd::borrow_balanace_mut<T>(house_data), user_stake_amount);
        balance::join(&mut user_balance_stake, house_stake);

        let game_uid = object::new(ctx);
        let player = tx_context::sender(ctx);

        let game = SlotGame<T>{
            id: game_uid,
            player,
            total_stake: house_stake,
            fee_rate: hd::fee_rate<T>(house_data),
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
        dof::add(hd::borrow_mut<T>(house_data), game_id, game);
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
            fee_rate,
            seed
        } = dof::remove<ID, SlotGame<T>>(hd::borrow_mut<T>(house_data), game_id);
        
        let msg_vec = object::uid_to_bytes(&id);
        vector::append(&mut msg_vec, seed);
        let public_key = hd::public_key<T>(house_data);

        // Step 1: Check the BLS signature, if its invalid abort.
        let is_sig_valid = bls12381_min_pk_verify(&bls_sig, &public_key, &msg_vec);
        assert!(is_sig_valid, EInvalidBlsSig);
        object::delete(id);

        //  Hash the beacon before taking the 1st byte.
        let (is_player_won, multiple_number) = roll::roll_player(
            result_roll_one,
            result_roll_two,
            result_roll_three
        );
        let hashed_beacon = blake2b256(&bls_sig);
        let first_byte = *vector::borrow(&hashed_beacon, 0);
        let player_won: bool = (is_player_won == first_byte % 2);

        // reward_distribution<T>(
        //     house_data,
        //     player_won,
        //     fee_rate,
        //     total_stake,
        //     player,
        //     ctx
        // )
    }

    // fun reward_distribution<T>(
    //     house_data: &HouseData<T>, 
    //     is_player_won: bool, 
    //     fee_rate: u64,
    //     total_stake: Balance<T>, 
    //     player: address,
    //     ctx: &mut TxContext
    // ){
    //     let stake_amount = balance::value(&total_stake);

    //     if(is_player_won){
    //         let fee_amount = fee_amount(stake_amount, fee_rate);
    //         let fees = balance::split(&mut total_stake, fee_amount);

    //         // events::emit_fee_collection(&fee_amount);
    //         // balance::join(hd::borrow_fees_mut(), fees);
    //         // let reward = coin::from_balance(total_stake, ctx);
    //         // transfer::public_transfer(reward, player);
    //     }else{
    //         balance::join(hd::borrow_balanace_mut(house_data), stake_amount);
    //     }
    // }
    
    fun game_exists<T>(house_data: &mut HouseData<T>, game_id: ID): bool {
        dof::exists_with_type<ID, SlotGame<T>>(hd::borrow_mut(house_data), game_id)
    }

    fun fee_amount(stake_amount: u64, fee_rate: u64): u64{
        return (((stake_amount/(GAME_RETURN as u64)) as u64) * ((fee_rate as u64)/(FEE_PRECISION as u64)) as u64)
    }
}