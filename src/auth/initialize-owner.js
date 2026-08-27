import { supabase } from '../config/supabase.js';

function showStatus(message, type = 'error') {
  const status = document.querySelector('[data-auth-status]');
  if (!status) return;
  status.textContent = message;
  status.dataset.type = type;
  status.hidden = false;
}

function setBusy(button, busy) {
  button.disabled = busy;
  button.setAttribute('aria-busy', String(busy));
  button.textContent = busy ? 'Initializing…' : 'Initialize owner';
}

async function initializeOwner(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const button = form.querySelector('button[type="submit"]');
  const email = form.email.value.trim();
  const password = form.password.value;
  const bootstrapToken = form.bootstrapToken.value.trim();

  if (!email || password.length < 12 || bootstrapToken.length < 32) {
    showStatus('Enter a valid email, a 12+ character password, and the one-time bootstrap credential.');
    return;
  }

  setBusy(button, true);
  try {
    const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
      email,
      password,
      options: { emailRedirectTo: `${window.location.origin}/Good/initialize-owner.html` }
    });

    if (signUpError && !/already registered|already exists/i.test(signUpError.message)) {
      throw signUpError;
    }

    let session = signUpData.session;
    if (!session) {
      const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({ email, password });
      if (signInError) {
        showStatus('Account created or already present. Confirm the email first, then return here and sign in again.');
        return;
      }
      session = signInData.session;
    }

    if (!session) throw new Error('AUTH_SESSION_NOT_CREATED');

    const { error: claimError } = await supabase.rpc('claim_initial_owner', {
      p_bootstrap_token: bootstrapToken
    });
    if (claimError) throw claimError;

    showStatus('Owner initialized successfully. Redirecting to sign in…', 'success');
    await supabase.auth.signOut();
    setTimeout(() => window.location.replace('/Good/auth.html'), 900);
  } catch (error) {
    console.error('Owner initialization failed:', error);
    const safeMessage = /INVALID_BOOTSTRAP_TOKEN/i.test(error?.message || '')
      ? 'The bootstrap credential is invalid or expired.'
      : /OWNER_ALREADY_INITIALIZED/i.test(error?.message || '')
        ? 'Owner initialization has already been completed.'
        : 'Owner initialization could not be completed securely.';
    showStatus(safeMessage);
  } finally {
    setBusy(button, false);
  }
}

document.querySelector('#owner-initialize')?.addEventListener('submit', initializeOwner);
