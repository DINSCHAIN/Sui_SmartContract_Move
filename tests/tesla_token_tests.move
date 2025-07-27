module 0x0::tesla_token_tests {
    use 0x0::step1_coin;
    use sui::coin;
    use sui::test_scenario as test;
    use sui::tx_context::TxContext;
    use sui::transfer;

    #[test]
    fun test_mint_tokens() {
        let sender = @0xA11CE; // Test account
        let mut scenario = test::begin(sender);
        
        // Test the minting functionality
        test::next_tx(&mut scenario, sender);
        {
            let ctx = test::ctx(&mut scenario);
            
            // Create coin via test-only helper
            let mut tcap = step1_coin::test_create_coin(ctx);
            
            // Mint tokens
            let minted_coin = coin::mint(&mut tcap, 1000, ctx);
            
            // Check that minted coin value is correct
            assert!(coin::value(&minted_coin) == 1000, 0);
            
            // Transfer the minted coin to sender (consume the coin)
            transfer::public_transfer(minted_coin, sender);
            
            // Transfer the treasury cap to sender (consume the tcap)
            transfer::public_transfer(tcap, sender);
        };
        
        // End the test scenario (consume the scenario)
        test::end(scenario);
    }

    #[test]
    fun test_mint_multiple_amounts() {
        let sender = @0xA11CE;
        let recipient = @0xB0B;
        let mut scenario = test::begin(sender);
        
        // Initialize
        test::next_tx(&mut scenario, sender);
        {
            let ctx = test::ctx(&mut scenario);
            let tcap = step1_coin::test_create_coin(ctx);
            transfer::public_transfer(tcap, sender);
        };
        
        // Test minting different amounts
        test::next_tx(&mut scenario, sender);
        {
            let mut tcap = test::take_from_sender<sui::coin::TreasuryCap<step1_coin::STEP1_COIN>>(&scenario);
            let ctx = test::ctx(&mut scenario);
            
            // Mint 500 tokens
            let coin1 = coin::mint(&mut tcap, 500, ctx);
            assert!(coin::value(&coin1) == 500, 1);
            transfer::public_transfer(coin1, recipient);
            
            // Mint 1500 tokens
            let coin2 = coin::mint(&mut tcap, 1500, ctx);
            assert!(coin::value(&coin2) == 1500, 2);
            transfer::public_transfer(coin2, recipient);
            
            test::return_to_sender(&scenario, tcap);
        };
        
        test::end(scenario);
    }

    #[test]
    fun test_coin_operations() {
        let sender = @0xA11CE;
        let mut scenario = test::begin(sender);
        
        // Setup
        test::next_tx(&mut scenario, sender);
        {
            let ctx = test::ctx(&mut scenario);
            let tcap = step1_coin::test_create_coin(ctx);
            transfer::public_transfer(tcap, sender);
        };
        
        // Mint and test coin operations
        test::next_tx(&mut scenario, sender);
        {
            let mut tcap = test::take_from_sender<sui::coin::TreasuryCap<step1_coin::STEP1_COIN>>(&scenario);
            let ctx = test::ctx(&mut scenario);
            
            // Mint a large amount
            let mut coin = coin::mint(&mut tcap, 10000, ctx);
            assert!(coin::value(&coin) == 10000, 0);
            
            // Split the coin
            let split_coin = coin::split(&mut coin, 3000, ctx);
            assert!(coin::value(&split_coin) == 3000, 1);
            assert!(coin::value(&coin) == 7000, 2);
            
            // Join coins back together
            coin::join(&mut coin, split_coin);
            assert!(coin::value(&coin) == 10000, 3);
            
            // Clean up
            transfer::public_transfer(coin, sender);
            test::return_to_sender(&scenario, tcap);
        };
        
        test::end(scenario);
    }
}