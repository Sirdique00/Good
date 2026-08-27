import { supabase } from '../config/supabase.js';

const OWNER_CONSOLE_PATH = '/Good/dashboard.html';

function showStatus(message, type = 'error') {
  const status = document.querySelector('[data-auth-status]');
  if (!status) return;
  status.textContent = message;
  status.dataset.type = type;
  status.hidden = false;
}

function setBusy(button, busy) {
  if (!button) return;
  button.disabled = busy;
  button.setAttribute('aria-busy', String(busy));
  button.textContent = busy ? 'Checking…' : 'Sign in';
}

async function isPlatformOwner() {
  const { data, error } = await supabase
    .from('owner_profiles')
    .select('id, display_name')
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  return data;
}

async function redirectIfAuthenticated() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return;

  try {
    const owner = await isPlatformOwner();
    if (owner) {
      window.location.replace(OWNER_CONSOLE_PATH);
      return;
    }
  } catch (error) {
    console.error('Owner authorization check failed:', error);
  }

  await supabase.auth.signOut({ scope: 'local' });
}

async function handleLogin(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const button = form.querySelector('button[type="submit"]');
  const email = form.email.value.trim();
  const password = form.password.value;

  if (!email || !password) {
    showStatus('Enter your owner email and password.');
    return;
  }

  setBusy(button, true);
  try {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;

    if (!data.session) {
      throw new Error('AUTH_SESSION_NOT_CREATED');
    }

    const owner = await isPlatformOwner();
    if (!owner) {
      await supabase.auth.signOut();
      showStatus('Access denied. This account is not authorized as the Sadeeq AI owner.');
      return;
    }

    window.location.replace(OWNER_CONSOLE_PATH);
  } catch (error) {
    console.error('Owner sign-in failed:', error);
    const message = error?.message === 'Invalid login credentials'
      ? 'Invalid email or password.'
      : 'Unable to sign in securely. Please try again.';
    showStatus(message);
  } finally {
    setBusy(button, false);
  }
}

async function handlePasswordReset(event) {
  event.preventDefault();
  const email = document.querySelector('#email')?.value.trim();
  if (!email) {
    showStatus('Enter your owner email first.');
    return;
  }

  try {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/Good/auth.html?mode=reset`
    });
    if (error) throw error;
    showStatus('If the account exists, a password reset email has been sent.', 'success');
  } catch (error) {
    console.error('Password reset request failed:', error);
    showStatus('Unable to request a password reset right now.');
  }
}

async function handleLogout() {
  await supabase.auth.signOut();
  window.location.replace('/Good/auth.html');
}

export async function requireOwner() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) {
    window.location.replace('/Good/auth.html');
    return null;
  }

  try {
    const owner = await isPlatformOwner();
    if (!owner) {
      await supabase.auth.signOut({ scope: 'local' });
      window.location.replace('/Good/auth.html?error=access-denied');
      return null;
    }
    return { session, owner };
  } catch (error) {
    console.error('Owner guard failed:', error);
    await supabase.auth.signOut({ scope: 'local' });
    window.location.replace('/Good/auth.html?error=authorization');
    return null;
  }
}

export function bindLogout() {
  document.querySelectorAll('[data-logout]').forEach((button) => {
    button.addEventListener('click', handleLogout);
  });
}

if (document.body?.dataset.page === 'auth') {
  document.querySelector('#owner-login')?.addEventListener('submit', handleLogin);
  document.querySelector('#reset-password')?.addEventListener('click', handlePasswordReset);
  redirectIfAuthenticated();

  const params = new URLSearchParams(window.location.search);
  if (params.get('error') === 'access-denied') {
    showStatus('Access denied. Only the platform owner can enter this console.');
  }
}
