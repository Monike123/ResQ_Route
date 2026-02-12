# 02 — Twilio SMS Alerting

## Objective
Send SOS alerts to emergency contacts via Twilio SMS with retry logic and delivery tracking.

---

## Edge Function: `send-sos-sms`

```typescript
// supabase/functions/send-sos-sms/index.ts
serve(async (req) => {
  const { contacts, userName, lat, lng, trackingLink, sosEventId } = await req.json();
  
  const accountSid = Deno.env.get('TWILIO_ACCOUNT_SID')!;
  const authToken = Deno.env.get('TWILIO_AUTH_TOKEN')!;
  const fromNumber = Deno.env.get('TWILIO_PHONE_NUMBER')!;

  const message = 
    `🚨 SOS ALERT from ${userName}\n` +
    `Location: https://maps.google.com/?q=${lat},${lng}\n` +
    `Track live: ${trackingLink}\n` +
    `Sent via ResQ Route at ${new Date().toLocaleTimeString('en-IN')}\n` +
    `If concerned, call 112 or go to them immediately.`;

  const results = [];

  for (const contact of contacts) {
    let attempts = 0;
    const maxAttempts = 3;
    let lastError = null;

    while (attempts < maxAttempts) {
      try {
        const response = await fetch(
          `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
          {
            method: 'POST',
            headers: {
              'Authorization': 'Basic ' + btoa(`${accountSid}:${authToken}`),
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
              To: `+91${contact.phone}`,
              From: fromNumber,
              Body: message,
            }),
          }
        );

        const result = await response.json();
        
        if (result.sid) {
          results.push({
            contact: contact.name,
            phone: contact.phone,
            status: 'sent',
            messageSid: result.sid,
            attempt: attempts + 1,
          });
          break;
        } else {
          throw new Error(result.message || 'SMS send failed');
        }
      } catch (error) {
        lastError = error;
        attempts++;
        // Exponential backoff: 1s, 2s, 4s
        await new Promise(r => setTimeout(r, 1000 * Math.pow(2, attempts - 1)));
      }
    }

    if (attempts >= maxAttempts) {
      results.push({
        contact: contact.name,
        phone: contact.phone,
        status: 'failed',
        error: lastError?.message,
        attempts: maxAttempts,
      });
    }
  }

  // Store delivery results
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  await supabase
    .from('sos_events')
    .update({ sms_delivery_status: results })
    .eq('id', sosEventId);

  return new Response(JSON.stringify({ results }));
});
```

---

## Delivery Status Webhook

Register a Twilio status callback to track delivery:

```typescript
// supabase/functions/twilio-status-callback/index.ts
serve(async (req) => {
  const formData = await req.formData();
  const messageSid = formData.get('MessageSid');
  const messageStatus = formData.get('MessageStatus'); // 'delivered', 'failed', 'undelivered'
  
  // Update delivery status in database
  // Query sos_events where sms_delivery_status contains this messageSid
  // Update the specific contact's delivery status
});
```

---

## Verification
- [ ] SMS sent to all 3 emergency contacts
- [ ] Retry logic with 3 attempts + backoff
- [ ] Delivery status tracked per contact
- [ ] SMS contains location link + tracking link
- [ ] Failed deliveries logged for admin review
