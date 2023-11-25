#[test_only]
module slots::test_house_data {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::test_scenario::{Self as tsc, Scenario};

    use slots::test_common::{Self as tc};
    use slots::house_data::{Self as hd, HouseData};

    const EWrongWithdrawAmount: u64 = 1;

    

    fun create_initial_balance_house(scenario: &mut Scenario, owner: address, house_funds: u64){
        let ctx = tsc::ctx(scenario);
        let coinA = coin::mint_for_testing<SUI>(house_funds, ctx);
        transfer::public_transfer(coinA, owner);
    }

    #[test]
    fun house_withdraws_balance(){

        let owner = @0xCAFE;

        let scenario_val = tsc::begin(owner);
        let scenario = &mut scenario_val;

        {
            create_initial_balance_house(scenario, owner, tc::get_initial_house_balance())
        };

        tc::init_house(scenario, owner, true);

        tsc::next_tx(scenario, owner);
        {
            let house_data = tsc::take_shared<HouseData<SUI>>(scenario);
            let ctx = tsc::ctx(scenario);
            hd::withdraw(&mut house_data, ctx);
            tsc::return_shared(house_data);
        };

        tsc::next_tx(scenario, owner);
        {
            let withdraw_coin = tsc::take_from_sender<Coin<SUI>>(scenario);
            assert!(coin::value(&withdraw_coin) == tc::get_initial_house_balance(), EWrongWithdrawAmount);
            tsc::return_to_sender(scenario, withdraw_coin);
        };

        tsc::end(scenario_val);
    }

    #[test]
    fun house_withdraws_fees(){
        let owner = @0xCAFE;
        let player = @0xDECAf;

        let scenario_val = tsc::begin(owner);
        let scenario = &mut scenario_val;
        {
            tc::fund_addresses(scenario, owner, player, tc::get_initial_house_balance(), tc::get_initial_house_balance());
        };
        tc::init_house(scenario, owner, true);
        let game_id = tc::create_game(scenario, player, tc::get_min_stake());
        let game_fees = tc::game_fees(scenario, game_id, owner);

        tc::end_game(scenario, game_id, owner, player, true);

        tsc::next_tx(scenario, owner);
        {
            let house_data = tsc::take_shared<HouseData<SUI>>(scenario);
            let ctx = tsc::ctx(scenario);
            hd::claim_fees(&mut house_data, ctx);
            tsc::return_shared(house_data);
        };

        tsc::next_tx(scenario, owner);
        {
            let withdraw_coin = tsc::take_from_sender<Coin<SUI>>(scenario);
            assert!(coin::value(&withdraw_coin) == game_fees, EWrongWithdrawAmount);
            tsc::return_to_sender(scenario, withdraw_coin);
        };
        tsc::end(scenario_val);
    }
}