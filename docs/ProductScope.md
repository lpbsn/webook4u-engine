# Product Scope

## Purpose

This document defines the current product scope of Webook4u from a product and strategy perspective.

Its role is to keep the MVP clearly framed, avoid false product signals, and make sure the team aligns on what the product is today, what it is not yet, and what it is preparing to become.

## Product Intent

Webook4u is currently positioned as a simple public booking engine designed to deliver a usable MVP quickly.

The current objective is not to build a complete booking platform.
The current objective is to make reservation selection, slot locking, and confirmation reliable enough to support iteration without creating a fragile base.

In its current form, the product is meant to solve one thing well:

- let an end user book a slot through a short, understandable public flow

## Current MVP Promise

Today, the product promise is:

- choose a location
- choose a service
- choose a date
- choose an available slot
- confirm the booking

This is a reservation MVP.
It is not yet a payment MVP.
It is not yet an operations MVP.
It is not yet a staff scheduling MVP.

## What the Product Actually Supports Today

The current product supports:

- a public booking page accessible through a client `slug`
- location selection
- service selection
- date selection
- available slot display
- temporary slot holding through a `pending` booking
- booking confirmation with first name, last name, and email
- a success page after confirmation

## Strategic Assumptions of the Current MVP

The MVP currently assumes:

- services are shared across all locations of the same client
- opening hours may still come from the client level as a temporary fallback
- the target model is still to move toward location-based availability rules
- each location is currently treated as if it had a single booking capacity at a given moment

This last point matters:

- one slot currently represents one available capacity per location
- the system does not yet model multiple staff members on the same slot

This is an intentional simplification for the MVP, not the intended long-term product model.

## What the Product Does Not Promise Yet

The product does not currently promise:

- online payment
- payment validation before booking confirmation
- payment failure management
- use of the `failed` booking state in the user flow
- cancellation
- rescheduling
- customer account management
- operational back-office workflows
- multi-staff capacity on the same slot
- CRM-driven slot ingestion

These are future evolution areas, not current product commitments.

## Main Product Risks of Misinterpretation

### Price display can be mistaken for payment

The interface currently shows a price and uses wording equivalent to "amount to pay".

Risk:

- stakeholders may think the MVP already includes payment
- users may assume the booking is tied to an online checkout flow
- future discussions may be biased by an incorrect understanding of what is already delivered

Current reality:

- the price is informational only
- confirmation is a booking confirmation, not a payment confirmation

### Stripe-related fields can be mistaken for active payment scope

The data model already contains Stripe-related fields.

Risk:

- people may think Stripe is already integrated into the product flow
- the roadmap may appear more advanced than it really is

Current reality:

- these fields are placeholders for a later payment phase
- they are not part of the active MVP flow

### The `failed` state can be mistaken for an active lifecycle

The booking model already exposes a `failed` state.

Risk:

- the team may start reasoning as if payment failures or booking failures are already productized

Current reality:

- the active MVP lifecycle is effectively based on `pending` and `confirmed`
- `failed` belongs to a later stage of the product

### Current capacity can be mistaken for the target operating model

The current slot engine behaves as if one location equals one available staff capacity at a time.

Risk:

- the current implementation may be mistaken for the target business model
- decisions may be taken as if slot uniqueness per location were a permanent rule

Current reality:

- this is only a simplification used to get the reservation engine stable
- the long-term model must support multiple available staff members on the same slot
- a single time slot may eventually need to appear more than once when multiple staff are available

### Internal slot calculation can be mistaken for the permanent availability source

Today, slot availability is derived internally from opening hours and bookings.

Risk:

- the team may overfit the architecture to an internal-only slot generation model

Current reality:

- in the future, slot availability may also be received directly from the client CRM
- the engine should therefore be thought of as evolving toward a model that can consume external availability, not only generate it internally

## Correct Product Narrative

The correct way to describe the product today is:

- Webook4u is a public booking engine
- the system temporarily holds a slot before confirmation
- a booking can be confirmed without payment
- displayed pricing is currently informational
- client-level opening hours are a transitional fallback
- current slot capacity is intentionally simplified to one implicit staff per location
- future availability may come from external client systems such as CRMs

## Strategic Direction

The next meaningful product step is not a large redesign.
The right direction is to harden the current reservation core while keeping the future model open.

The strategy should be:

- make the current booking engine stable and maintainable
- reduce false product signals in wording and product communication
- clarify the real MVP promise everywhere
- keep the domain ready for staff capacity
- keep the domain ready for external availability sources
- only then add payment

## Product Evolution Path

The likely evolution path is:

1. stabilize public booking and confirmation
2. remove ambiguity in product wording
3. clarify the domain around locations and availability
4. prepare for multi-staff capacity
5. prepare for CRM-driven slot ingestion
6. add payment and related failure states

## Summary

Webook4u today is a booking MVP with a narrow and deliberate promise:

- find a slot
- hold it briefly
- confirm the booking

The current product is intentionally simpler than the target model.

It does not yet cover:

- payment
- complex booking lifecycle management
- multi-staff capacity
- CRM-native availability ingestion

That is acceptable, as long as this simplified MVP is described honestly and does not pretend to solve the next product stage before it actually does.
