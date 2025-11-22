# TicketChain - Decentralized Event Ticketing & NFT Tickets

A blockchain-based event ticketing platform built on Stacks using Clarity smart contracts. TicketChain eliminates ticket scalping, provides transparent resale controls, ensures verifiable ticket ownership, and creates a fair marketplace for event tickets through NFT technology and smart contract automation.

## Overview

TicketChain revolutionizes the event ticketing industry by transforming tickets into non-fungible tokens (NFTs) on the blockchain. This approach eliminates counterfeit tickets, prevents predatory scalping through price controls, ensures transparent ownership tracking, and creates a fair secondary market—all while giving event organizers and fans unprecedented control and transparency.

## Key Features

### For Event Organizers
- **Event Creation**: Launch events with customizable ticket parameters
- **Price Control**: Set base ticket prices with anti-scalping protections
- **Resale Management**: Enable/disable resales and control markup limits
- **Ticket Verification**: Scan and verify tickets at venue entrance
- **Event Management**: Update dates, cancel events, track statistics
- **Revenue Tracking**: Monitor sales and earnings in real-time
- **Attendee Lists**: Access verified attendee information

### For Ticket Holders
- **Verifiable Ownership**: NFT tickets prove authentic ownership
- **Resale Options**: List tickets on secondary market (if enabled)
- **Price Protection**: Maximum 150% markup prevents extreme scalping
- **Gifting**: Transfer tickets to friends/family for free
- **Usage Tracking**: Clear indication of used vs. valid tickets
- **Transparent History**: View complete ownership chain

### Platform Features
- **Anti-Scalping**: Hard cap on resale prices (150% of purchase price)
- **Counterfeit Prevention**: Blockchain-verified authentic tickets
- **Secondary Market**: Built-in peer-to-peer resale marketplace
- **Smart Verification**: QR code / blockchain-based entry validation
- **Revenue Transparency**: All transactions on-chain and auditable
- **Platform Fee**: 3% fee on all ticket sales

## Architecture

### Data Structures

#### Events
- Unique event ID and organizer identity
- Event details (name, venue, date)
- Ticket inventory (total, sold count)
- Pricing (base price)
- Resale policy (enabled/disabled)
- Active status
- Creation timestamp

#### Tickets (NFTs)
- Unique ticket ID
- Event association
- Current owner
- Purchase price history
- Usage status (used/unused)
- Resale price (if listed)
- Transfer count (ownership changes)
- Creation timestamp

#### Event Attendees
- Check-in records
- Ticket association
- Attendee identity
- Check-in timestamp
- Verification status

#### Organizer Statistics
- Total events created
- Total tickets sold
- Total earnings

#### Ticket Transfers
- Complete transfer history
- Buyer and seller identity
- Transaction price
- Timestamp

## Smart Contract Functions

### Event Management

#### `create-event`
```clarity
(create-event (name (string-ascii 128)) 
              (venue (string-ascii 128)) 
              (event-date uint) 
              (total-tickets uint) 
              (base-price uint) 
              (resale-enabled bool))
```
Create a new event with ticketing parameters.

**Parameters:**
- `name`: Event name/title
- `venue`: Event location
- `event-date`: Block height when event occurs
- `total-tickets`: Total ticket supply
- `base-price`: Initial ticket price (micro-STX)
- `resale-enabled`: Allow secondary market sales

**Returns:** Event ID

**Validations:**
- Total tickets must be greater than 0
- Base price must be greater than 0
- Event date must be in the future

**Example:**
```clarity
;; Create concert with 1000 tickets at 50 STX each, resale allowed
(contract-call? .ticketchain create-event 
  "Summer Music Festival 2025" 
  "Madison Square Garden, NYC" 
  u110000 
  u1000 
  u50000000 
  true)
;; => (ok u1)
```

#### `cancel-event`
```clarity
(cancel-event (event-id uint))
```
Cancel an event (organizer only).

**Parameters:**
- `event-id`: Event to cancel

**Returns:** Success confirmation

**Access:** Event organizer only

**Example:**
```clarity
(contract-call? .ticketchain cancel-event u1)
;; => (ok true)
```

#### `update-event-date`
```clarity
(update-event-date (event-id uint) (new-date uint))
```
Update event date (organizer only).

**Parameters:**
- `event-id`: Event to update
- `new-date`: New event date (block height)

**Returns:** Success confirmation

**Validations:**
- New date must be in the future
- Only organizer can update

**Example:**
```clarity
;; Postpone event by 1000 blocks
(contract-call? .ticketchain update-event-date u1 u111000)
;; => (ok true)
```

### Ticket Purchase & Ownership

#### `purchase-ticket`
```clarity
(purchase-ticket (event-id uint))
```
Purchase a ticket for an event (primary market).

**Parameters:**
- `event-id`: Event to purchase ticket for

**Returns:** Ticket ID (NFT)

**Validations:**
- Event must be active
- Tickets must be available (not sold out)
- Event date must be in the future

**Effects:**
- Creates NFT ticket with unique ID
- Increases sold ticket count
- Records purchase price
- Adds to platform revenue

**Example:**
```clarity
(contract-call? .ticketchain purchase-ticket u1)
;; => (ok u1)  ;; Ticket ID 1 minted
```

#### `use-ticket`
```clarity
(use-ticket (ticket-id uint))
```
Mark ticket as used (ticket holder enters event).

**Parameters:**
- `ticket-id`: Ticket to use

**Returns:** Success confirmation

**Validations:**
- Caller must be ticket owner
- Ticket must not already be used

**Effects:**
- Sets used flag to true
- Prevents further usage
- Records usage on-chain

**Example:**
```clarity
(contract-call? .ticketchain use-ticket u1)
;; => (ok true)
```

### Secondary Market (Resale)

#### `list-for-resale`
```clarity
(list-for-resale (ticket-id uint) (resale-price uint))
```
List ticket on secondary market for resale.

**Parameters:**
- `ticket-id`: Ticket to sell
- `resale-price`: Asking price (micro-STX)

**Returns:** Success confirmation

**Validations:**
- Caller must be ticket owner
- Ticket must not be used
- Resale must be enabled for event
- Resale price ≤ 150% of purchase price (anti-scalping)

**Example:**
```clarity
;; List ticket bought at 50 STX for 70 STX (40% markup, under 150% limit)
(contract-call? .ticketchain list-for-resale u1 u70000000)
;; => (ok true)
```

#### `buy-resale-ticket`
```clarity
(buy-resale-ticket (ticket-id uint))
```
Purchase a ticket from secondary market.

**Parameters:**
- `ticket-id`: Ticket to purchase

**Returns:** Success confirmation

**Validations:**
- Ticket must be listed for resale
- Ticket must not be used

**Effects:**
- Transfers ownership to buyer
- Removes resale listing
- Increments transfer count
- Records transaction

**Example:**
```clarity
(contract-call? .ticketchain buy-resale-ticket u1)
;; => (ok true)
```

#### `cancel-listing`
```clarity
(cancel-listing (ticket-id uint))
```
Remove ticket from secondary market.

**Parameters:**
- `ticket-id`: Ticket to delist

**Returns:** Success confirmation

**Validations:**
- Caller must be ticket owner
- Ticket must be listed

**Example:**
```clarity
(contract-call? .ticketchain cancel-listing u1)
;; => (ok true)
```

### Ticket Transfer & Gifting

#### `gift-ticket`
```clarity
(gift-ticket (ticket-id uint) (recipient principal))
```
Transfer ticket to another person for free (gift).

**Parameters:**
- `ticket-id`: Ticket to gift
- `recipient`: Recipient's wallet address

**Returns:** Success confirmation

**Validations:**
- Caller must be ticket owner
- Ticket must not be used

**Effects:**
- Transfers ownership to recipient
- Increments transfer count
- No payment required

**Example:**
```clarity
;; Gift ticket to friend
(contract-call? .ticketchain gift-ticket u1 'ST1FR13ND123)
;; => (ok true)
```

### Venue Operations

#### `verify-ticket`
```clarity
(verify-ticket (ticket-id uint))
```
Verify and check-in ticket at venue entrance (organizer only).

**Parameters:**
- `ticket-id`: Ticket to verify

**Returns:** Attendee ID

**Access:** Event organizer only

**Validations:**
- Ticket must not already be used
- Only organizer can verify

**Effects:**
- Creates attendee record
- Records check-in time
- Marks as verified

**Example:**
```clarity
(contract-call? .ticketchain verify-ticket u1)
;; => (ok u1)  ;; Attendee ID 1 created
```

### Read-Only Functions

#### `get-event`
```clarity
(get-event (event-id uint))
```
Retrieve complete event details.

**Returns:** Event data structure or none

**Example:**
```clarity
(contract-call? .ticketchain get-event u1)
;; => (some {organizer: ST1..., name: "Summer Music Festival", ...})
```

#### `get-ticket`
```clarity
(get-ticket (ticket-id uint))
```
Retrieve complete ticket details.

**Returns:** Ticket data structure or none

**Example:**
```clarity
(contract-call? .ticketchain get-ticket u1)
;; => (some {event-id: u1, owner: ST1..., used: false, ...})
```

#### `get-event-stats`
```clarity
(get-event-stats (event-id uint))
```
Get event sales statistics.

**Returns:**
```clarity
{
  sold: uint,      // Tickets sold
  total: uint,     // Total tickets
  revenue: uint    // Total revenue
}
```

**Example:**
```clarity
(contract-call? .ticketchain get-event-stats u1)
;; => (ok {sold: u750, total: u1000, revenue: u37500000000})
```

#### `get-organizer-stats`
```clarity
(get-organizer-stats (organizer principal))
```
Get organizer performance statistics.

**Returns:** Organizer stats or none

#### `get-attendee`
```clarity
(get-attendee (attendee-id uint))
```
Retrieve attendee check-in record.

**Returns:** Attendee data or none

#### `get-platform-revenue`
```clarity
(get-platform-revenue)
```
Get total platform revenue.

**Returns:** Total revenue in micro-STX

## Constants & Configuration

### Anti-Scalping Protection
- **Maximum Resale Markup**: 150% of purchase price
- **Example**: Ticket bought at 50 STX can be resold for max 75 STX

### Platform Parameters
- **Platform Fee**: 3% on all sales
- **Resale Control**: Organizer enables/disables per event

### Error Codes
- `u100` (`err-owner-only`): Contract owner operation only
- `u101` (`err-not-found`): Event, ticket, or entity not found
- `u102` (`err-unauthorized`): Insufficient permissions
- `u103` (`err-sold-out`): No tickets available
- `u104` (`err-invalid-price`): Invalid pricing or markup violation
- `u105` (`err-event-passed`): Event date already occurred
- `u106` (`err-already-used`): Ticket already used for entry
- `u107` (`err-transfer-disabled`): Resale not allowed for event

## Usage Examples

### Complete Event Workflow

```clarity
;; PHASE 1: Event Creation

;; Organizer creates music festival
(contract-call? .ticketchain create-event 
  "Blockchain Music Festival 2025" 
  "Crypto Arena, Los Angeles" 
  u115000 
  u5000 
  u75000000 
  true)
;; => (ok u1)

;; PHASE 2: Primary Ticket Sales

;; Alice buys ticket
(contract-call? .ticketchain purchase-ticket u1)
;; => (ok u1)  ;; Ticket ID 1

;; Bob buys ticket
(contract-call? .ticketchain purchase-ticket u1)
;; => (ok u2)  ;; Ticket ID 2

;; Carol buys ticket
(contract-call? .ticketchain purchase-ticket u1)
;; => (ok u3)  ;; Ticket ID 3

;; PHASE 3: Secondary Market Activity

;; Bob can't attend, lists ticket for resale
;; Bought at 75 STX, listing at 100 STX (33% markup, under 150% limit)
(contract-call? .ticketchain list-for-resale u2 u100000000)
;; => (ok true)

;; Dave buys Bob's ticket
(contract-call? .ticketchain buy-resale-ticket u2)
;; => (ok true)
;; Ticket #2 now owned by Dave

;; PHASE 4: Gifting

;; Alice decides to gift her ticket to her friend Emma
(contract-call? .ticketchain gift-ticket u1 'ST1EMMA456)
;; => (ok true)
;; Ticket #1 now owned by Emma

;; PHASE 5: Event Day - Venue Check-in

;; Emma arrives at venue, organizer scans ticket
(contract-call? .ticketchain verify-ticket u1)
;; => (ok u1)  ;; Attendee record created

;; Emma enters, marks ticket as used
(contract-call? .ticketchain use-ticket u1)
;; => (ok true)

;; Dave arrives and checks in
(contract-call? .ticketchain verify-ticket u2)
;; => (ok u2)
(contract-call? .ticketchain use-ticket u2)
;; => (ok true)

;; Carol arrives and checks in
(contract-call? .ticketchain verify-ticket u3)
;; => (ok u3)
(contract-call? .ticketchain use-ticket u3)
;; => (ok true)

;; PHASE 6: Post-Event Analytics

;; Check event statistics
(contract-call? .ticketchain get-event-stats u1)
;; => (ok {sold: u5000, total: u5000, revenue: u375000000000})
;; 5,000 tickets sold at 75 STX = 375,000 STX revenue
```

### Anti-Scalping Protection in Action

```clarity
;; Scalper attempts to exploit the system

;; Scalper buys ticket at base price
(contract-call? .ticketchain purchase-ticket u1)
;; => (ok u100)  ;; Ticket bought at 75 STX

;; Scalper tries to list at 10x markup (1000% = 750 STX)
(contract-call? .ticketchain list-for-resale u100 u750000000)
;; => (err u104)  ;; ERROR! Exceeds 150% limit

;; Maximum allowed: 75 STX × 150% = 112.5 STX
(contract-call? .ticketchain list-for-resale u100 u112500000)
;; => (ok true)  ;; Success! Within 150% limit

;; Scalping is prevented - fans get fair prices
```

### Event Postponement Scenario

```clarity
;; Organizer needs to postpone event

;; Original date: block 115000
;; New date: block 120000 (delayed by ~35 days)

(contract-call? .ticketchain update-event-date u1 u120000)
;; => (ok true)

;; All existing tickets remain valid for new date
;; Ticket holders automatically notified via event logs
```

### Sold Out Event with Secondary Market

```clarity
;; Hot concert sells out

;; Last ticket purchased
(contract-call? .ticketchain purchase-ticket u1)
;; => (ok u5000)  ;; Ticket 5000 of 5000

;; Fan tries to buy after sold out
(contract-call? .ticketchain purchase-ticket u1)
;; => (err u103)  ;; ERROR! Sold out

;; Fan checks secondary market
;; Multiple tickets listed by attendees who can't make it

;; Find ticket listed at fair price
(contract-call? .ticketchain get-ticket u247)
;; => {resale-price: (some u90000000), ...}  ;; 90 STX (20% markup)

;; Purchase from secondary market
(contract-call? .ticketchain buy-resale-ticket u247)
;; => (ok true)  ;; Success!
```

### Ticket Fraud Prevention

```clarity
;; Traditional scenario: Someone tries to use fake ticket
;; With TicketChain: Impossible

;; At venue entrance, organizer verifies ticket
(contract-call? .ticketchain verify-ticket u1)
;; => (ok u1)  ;; Verified! Blockchain confirms authenticity

;; Fraudster tries to use same ticket twice
(contract-call? .ticketchain verify-ticket u1)
;; => (err u106)  ;; ERROR! Already used

;; Smart contract prevents double-entry and counterfeits
```

## Anti-Scalping Mechanism

### Price Control Formula

```
Maximum Resale Price = Purchase Price × 150%

Examples:
- Purchase: 50 STX → Max Resale: 75 STX
- Purchase: 100 STX → Max Resale: 150 STX
- Purchase: 200 STX → Max Resale: 300 STX
```

### Why 150%?

**Balanced Approach:**
- Allows legitimate resale with modest profit
- Prevents predatory scalping (500-1000%+ markups)
- Protects fans from extreme price gouging
- Maintains market liquidity

**Traditional vs. TicketChain:**

| Scenario | Traditional | TicketChain |
|----------|------------|-------------|
| Base Price | $100 | 100 STX |
| Scalper Markup | $500-2000+ | Max 150 STX |
| Fan Protection | None | 50% max markup |
| Organizer Control | Limited | Full control |

## Economic Model

### Revenue Distribution

**Primary Sale:**
```
Ticket Price: 100 STX
Platform Fee: 3 STX (3%)
Organizer Receives: 97 STX
```

**Secondary Sale:**
```
Resale Price: 130 STX
Platform Fee: 3.9 STX (3%)
Seller Receives: 126.1 STX
```

### Event Economics Example

**Concert Event:**
```
Venue Capacity: 10,000 tickets
Ticket Price: 75 STX
Total Revenue: 750,000 STX

Platform Fee (3%): 22,500 STX
Organizer Revenue: 727,500 STX

Secondary Market:
- 20% of tickets resold (2,000 tickets)
- Average resale: 95 STX (26.7% markup)
- Secondary revenue: 190,000 STX
- Platform fee: 5,700 STX
```

### Fan Benefits

**Cost Savings vs. Traditional:**
```
Traditional Scalping:
- Base: $100
- Scalper Price: $500
- Fan Pays: $500 (400% markup)

TicketChain:
- Base: 100 STX
- Max Resale: 150 STX
- Fan Pays: 150 STX (50% markup max)

Savings: $350 or 70% reduction in scalping cost
```

## Security Considerations

### Ticket Authenticity
- Each ticket is unique NFT with on-chain ID
- Blockchain verification prevents counterfeits
- Ownership history immutably recorded
- Used status tracked permanently

### Anti-Fraud Mechanisms
- Cannot use ticket twice (used flag)
- Cannot transfer after use
- Cannot list fake tickets
- Organizer verification at entrance

### Access Control
- Only ticket owner can use/transfer
- Only organizer can verify at venue
- Only organizer can cancel/update event
- Price controls prevent scalping

### Smart Contract Security
- Input validation on all functions
- Ownership checks before operations
- Event date validation
- Sold-out prevention
- No re-entry vulnerabilities

## Integration Examples

### QR Code Generation

```javascript
// Generate QR code for ticket
async function generateTicketQR(ticketId) {
  const ticket = await getTicket(ticketId);
  
  const ticketData = {
    ticketId,
    eventId: ticket.eventId,
    owner: ticket.owner,
    signature: await signTicket(ticketId, ticket.owner)
  };
  
  const qrCode = await QRCode.toDataURL(JSON.stringify(ticketData));
  return qrCode;
}
```

### Venue Check-In System

```javascript
// Scan and verify ticket at entrance
async function scanTicket(qrData) {
  const ticketData = JSON.parse(qrData);
  
  // Verify signature
  const isValid = await verifySignature(ticketData);
  if (!isValid) return {error: 'Invalid ticket'};
  
  // Check on blockchain
  const ticket = await contractCall('get-ticket', [ticketData.ticketId]);
  
  if (ticket.used) {
    return {error: 'Ticket already used'};
  }
  
  // Verify ticket
  await contractCall('verify-ticket', [ticketData.ticketId]);
  
  return {success: true, attendeeId: result};
}
```

### Event Dashboard

```javascript
// Real-time event analytics
async function getEventDashboard(eventId) {
  const event = await contractCall('get-event', [eventId]);
  const stats = await contractCall('get-event-stats', [eventId]);
  
  return {
    name: event.name,
    venue: event.venue,
    date: event.eventDate,
    ticketsSold: stats.sold,
    totalTickets: stats.total,
    soldOutPercentage: (stats.sold / stats.total) * 100,
    revenue: stats.revenue,
    status: event.active ? 'Active' : 'Cancelled'
  };
}
```

### Secondary Market Listing

```javascript
// List ticket on marketplace
async function listTicketForSale(ticketId, price) {
  const ticket = await getTicket(ticketId);
  const maxPrice = ticket.purchasePrice * 1.5;
  
  if (price > maxPrice) {
    throw new Error(`Price exceeds maximum: ${maxPrice} STX`);
  }
  
  await contractCall('list-for-resale', [ticketId, price]);
  
  // Notify marketplace
  await notifyMarketplace(ticketId, price);
}
```

## Testing Recommendations

### Unit Tests
- [x] Event creation with valid parameters
- [x] Event creation with invalid parameters (should fail)
- [x] Ticket purchase when available
- [x] Ticket purchase when sold out (should fail)
- [x] Ticket purchase for past event (should fail)
- [x] Resale listing within price limit
- [x] Resale listing exceeding limit (should fail)
- [x] Resale purchase
- [x] Ticket gifting
- [x] Ticket usage (single use)
- [x] Double usage prevention (should fail)
- [x] Event cancellation
- [x] Event date update
- [x] Ticket verification by organizer

### Integration Tests
- [ ] Complete event lifecycle
- [ ] Multiple ticket purchases and transfers
- [ ] Secondary market scenarios
- [ ] Sold-out event handling
- [ ] Event postponement with existing tickets
- [ ] Mass check-in simulation

### Security Tests
- [ ] Unauthorized access attempts
- [ ] Price manipulation attempts
- [ ] Double-spend prevention
- [ ] Counterfeit ticket attempts
- [ ] Re-entry attack scenarios

### Economic Tests
- [ ] Revenue calculations
- [ ] Platform fee distributions
- [ ] Price limit enforcement
- [ ] Edge case: exactly 150% markup
- [ ] Multiple resales of same ticket

## Known Limitations & Future Enhancements

### Current Limitations
1. **No Actual Payments**: Contract tracks but doesn't transfer STX
2. **No Refunds**: No cancellation refund mechanism
3. **Limited Ticket Metadata**: Basic information only
4. **No Seat Selection**: General admission only
5. **No Tiered Pricing**: Single price per event
6. **Fixed 150% Limit**: Not customizable per event

### Planned Enhancements

**Phase 1: Core Improvements**
- [ ] Implement actual STX transfers
- [ ] Refund mechanism for cancelled events
- [ ] Enhanced ticket metadata (seat numbers, sections)
- [ ] Multiple ticket purchase in one transaction
- [ ] Batch ticket operations

**Phase 2: Advanced Features**
- [ ] Tiered pricing (VIP, General, etc.)
- [ ] Reserved seating system
- [ ] Dynamic pricing based on demand
- [ ] Customizable resale markup per event
- [ ] Auction-based resale option
- [ ] Early bird discounts

**Phase 3: Marketplace**
- [ ] Orderbook for secondary market
- [ ] Bid/ask system
- [ ] Price alerts
- [ ] Ticket swap functionality
- [ ] Bundle deals
- [ ] Group ticket purchases

**Phase 4: Ecosystem**
- [ ] Multi-day event passes
- [ ] Season tickets
- [ ] Loyalty rewards program
- [ ] NFT collectible tickets (keep after event)
- [ ] Proof of attendance tokens
- [ ] Artist/venue partnerships
- [ ] Cross-chain compatibility

## Regulatory Considerations

### Consumer Protection
- Transparent pricing and fees
- Anti-scalping protections
- Refund policies for cancellations
- Clear terms of service

### Tax Compliance
- Revenue reporting requirements
- Secondary market sales tracking
- Platform fee documentation
- 1099 forms for organizers

### Data Privacy
- GDPR compliance for attendee data
- Optional anonymity for buyers
- Secure data storage
- Right to deletion (where applicable)

## Deployment

### Prerequisites
- Clarinet CLI
- Stacks wallet with STX
- Event management interface
- QR code generation system
- Venue check-in hardware/software

### Deployment Steps

```bash
# 1. Test thoroughly
clarinet test

# 2. Validate contract
clarinet check

# 3. Deploy to testnet
clarinet deploy --testnet

# 4. Test with real events
clarinet console --testnet

# 5. Production deployment
clarinet deploy --mainnet
```

## License

MIT License - See LICENSE file for details

## Disclaimer

This smart contract is provided for educational purposes. It is NOT a complete ticketing solution. Users must:

- Comply with local event regulations
- Handle tax reporting obligations
- Implement proper refund policies
- Secure venue check-in systems
- Provide customer support
- Consider accessibility requirements
- Handle disputes appropriately

## Support & Contributing

- GitHub: [repository-url]
- Documentation: [docs-link]
- Discord: [community-link]
- Support: support@ticketchain.xyz

## Acknowledgments

Built to create a fairer event industry where fans get tickets at reasonable prices and organizers maintain control. Special thanks to the Stacks community for enabling innovative NFT applications.
