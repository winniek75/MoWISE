// ============================================================
// Stripe integration - checkout session creation
// For MVP: direct to Stripe Checkout via Supabase Edge Function
// ============================================================

const STRIPE_PRICES = {
  basic: 'price_basic_980',  // TODO: Replace with real Stripe Price ID
  pro: 'price_pro_2980',     // TODO: Replace with real Stripe Price ID
} as const

export async function createCheckoutSession(plan: 'basic' | 'pro', userId: string): Promise<string> {
  // TODO: Call Supabase Edge Function that creates a Stripe Checkout Session
  // const { data, error } = await supabase.functions.invoke('create-checkout', {
  //   body: { plan, userId, priceId: STRIPE_PRICES[plan] }
  // })
  // if (error) throw error
  // return data.url

  // Placeholder - will redirect to Stripe
  console.warn('[stripe] Checkout not yet configured. Plan:', plan, 'User:', userId)
  throw new Error('Stripe Checkout is not yet configured')
}

export async function createPortalSession(userId: string): Promise<string> {
  // TODO: Call Supabase Edge Function for Stripe Customer Portal
  console.warn('[stripe] Portal not yet configured. User:', userId)
  throw new Error('Stripe Portal is not yet configured')
}
