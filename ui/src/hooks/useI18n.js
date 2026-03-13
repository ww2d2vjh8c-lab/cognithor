/**
 * React hook for reactive i18n.
 * Re-renders the component when the locale changes.
 */
import { useState, useEffect } from "react";
import { t, getLocale, setLocale, onLocaleChange } from "../utils/i18n";

export function useI18n() {
  const [, setTick] = useState(0);

  useEffect(() => {
    return onLocaleChange(() => setTick((n) => n + 1));
  }, []);

  return { t, locale: getLocale(), setLocale };
}
