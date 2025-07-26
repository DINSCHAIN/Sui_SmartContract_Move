/// Tesla Allo Stock Token (aTSLA) - SUI Move Implementation
/// Equivalent to the Solidity ERC20 contract with minting and burning capabilities
module tesla_token::atsla {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::url::{Self, Url};
    use std::option;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use std::string;
    use sui::vec_set::{Self, VecSet};

    // ===== Error Codes =====
    const ENotAuthorized: u64 = 1;
    const EInvalidAmount: u64 = 2;

    // ===== Structs =====

    /// One-time witness for the coin
    public struct ATSLA has drop {}

    /// Admin capability for role management
    public struct AdminCap has key, store {
        id: UID,
    }

    /// Minter capability - similar to MINTER_ROLE in Solidity
    public struct MinterCap has key, store {
        id: UID,
    }

    /// Registry to track authorized minters (similar to AccessControl)
    public struct MinterRegistry has key {
        id: UID,
        minters: VecSet<address>,
        admin: address,
    }

    // ===== Events =====
    
    /// Emitted when tokens are minted
    public struct MintEvent has copy, drop {
        recipient: address,
        amount: u64,
    }

    /// Emitted when tokens are burned  
    public struct BurnEvent has copy, drop {
        burner: address,
        amount: u64,
    }

    /// Emitted when a new minter is added
    public struct MinterAdded has copy, drop {
        minter: address,
        admin: address,
    }

    /// Emitted when a minter is removed
    public struct MinterRemoved has copy, drop {
        minter: address,
        admin: address,
    }

    // ===== Initialization =====

    /// Initialize the coin - called once when the module is published
    /// This is equivalent to the Solidity constructor
    fun init(witness: ATSLA, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<ATSLA>(
            witness,
            18, // decimals - equivalent to _decimals in Solidity
            b"aTSLA",
            b"Tesla Allo Stock",
            b"A mintable and burnable token representing Tesla exposure",
            option::none<Url>(),
            ctx
        );

        // Create admin capability for the deployer
        let admin_cap = AdminCap {
            id: object::new(ctx),
        };

        // Create minter registry
        let minter_registry = MinterRegistry {
            id: object::new(ctx),
            minters: vec_set::empty<address>(),
            admin: tx_context::sender(ctx),
        };

        // Transfer treasury cap to the deployer (equivalent to granting DEFAULT_ADMIN_ROLE)
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        
        // Transfer admin cap to the deployer
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        
        // Share the minter registry
        transfer::share_object(minter_registry);
        
        // Freeze the metadata object
        transfer::public_freeze_object(metadata);
    }

    // ===== Admin Functions =====

    /// Grant minter role to an address (equivalent to grantRole(MINTER_ROLE, account))
    public fun grant_minter_role(
        _: &AdminCap,
        registry: &mut MinterRegistry,
        new_minter: address,
        ctx: &mut TxContext
    ) {
        vec_set::insert(&mut registry.minters, new_minter);
        
        // Create and transfer minter capability
        let minter_cap = MinterCap {
            id: object::new(ctx),
        };
        transfer::public_transfer(minter_cap, new_minter);

        // Emit event
        sui::event::emit(MinterAdded {
            minter: new_minter,
            admin: tx_context::sender(ctx),
        });
    }

    /// Revoke minter role from an address (equivalent to revokeRole(MINTER_ROLE, account))
    public fun revoke_minter_role(
        _: &AdminCap,
        registry: &mut MinterRegistry,
        minter: address,
        ctx: &mut TxContext
    ) {
        vec_set::remove(&mut registry.minters, &minter);

        // Emit event
        sui::event::emit(MinterRemoved {
            minter: minter,
            admin: tx_context::sender(ctx),
        });
    }

    /// Check if an address has minter role (equivalent to hasRole(MINTER_ROLE, account))
    public fun has_minter_role(registry: &MinterRegistry, account: address): bool {
        vec_set::contains(&registry.minters, &account)
    }

    // ===== Minting Functions =====

    /// Mint tokens to a recipient (equivalent to mint function in Solidity)
    /// Only accounts with MinterCap can call this
    public fun mint(
        _: &MinterCap,
        treasury_cap: &mut TreasuryCap<ATSLA>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, EInvalidAmount);
        
        let coin = coin::mint(treasury_cap, amount, ctx);
        transfer::public_transfer(coin, recipient);

        // Emit mint event
        sui::event::emit(MintEvent {
            recipient,
            amount,
        });
    }

    /// Mint tokens and return the coin object (useful for composability)
    public fun mint_and_return(
        _: &MinterCap,
        treasury_cap: &mut TreasuryCap<ATSLA>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<ATSLA> {
        assert!(amount > 0, EInvalidAmount);
        
        let coin = coin::mint(treasury_cap, amount, ctx);

        // Emit mint event
        sui::event::emit(MintEvent {
            recipient: tx_context::sender(ctx),
            amount,
        });

        coin
    }

    // ===== Burning Functions =====

    /// Burn tokens from caller's balance (equivalent to burn() in ERC20Burnable)
    public fun burn(
        treasury_cap: &mut TreasuryCap<ATSLA>,
        coin: Coin<ATSLA>,
        ctx: &mut TxContext
    ) {
        let amount = coin::value(&coin);
        coin::burn(treasury_cap, coin);

        // Emit burn event
        sui::event::emit(BurnEvent {
            burner: tx_context::sender(ctx),
            amount,
        });
    }

    /// Burn a specific amount from a coin, returning the remainder
    public fun burn_amount(
        treasury_cap: &mut TreasuryCap<ATSLA>,
        coin: &mut Coin<ATSLA>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(amount > 0, EInvalidAmount);
        assert!(coin::value(coin) >= amount, EInvalidAmount);
        
        let to_burn = coin::split(coin, amount, ctx);
        coin::burn(treasury_cap, to_burn);

        // Emit burn event
        sui::event::emit(BurnEvent {
            burner: tx_context::sender(ctx),
            amount,
        });
    }

    // ===== Utility Functions =====

    /// Get total supply (equivalent to totalSupply() in ERC20)
    public fun total_supply(treasury_cap: &TreasuryCap<ATSLA>): u64 {
        coin::total_supply(treasury_cap)
    }

    /// Get the balance of a coin object (equivalent to balanceOf for a specific coin)
    public fun balance(coin: &Coin<ATSLA>): u64 {
        coin::value(coin)
    }

    // ===== Transfer Admin Role =====

    /// Transfer admin capability to a new admin
    public fun transfer_admin(admin_cap: AdminCap, new_admin: address) {
        transfer::public_transfer(admin_cap, new_admin);
    }

    
}