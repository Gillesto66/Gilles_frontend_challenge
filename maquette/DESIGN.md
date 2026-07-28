---
name: Lumina Transit
colors:
  surface: '#121317'
  surface-dim: '#121317'
  surface-bright: '#38393d'
  surface-container-lowest: '#0d0e12'
  surface-container-low: '#1a1b1f'
  surface-container: '#1e1f23'
  surface-container-high: '#292a2e'
  surface-container-highest: '#343539'
  on-surface: '#e3e2e7'
  on-surface-variant: '#b9cacb'
  inverse-surface: '#e3e2e7'
  inverse-on-surface: '#2f3034'
  outline: '#849495'
  outline-variant: '#3b494b'
  surface-tint: '#00dbe9'
  primary: '#dbfcff'
  on-primary: '#00363a'
  primary-container: '#00f0ff'
  on-primary-container: '#006970'
  inverse-primary: '#006970'
  secondary: '#ffb59a'
  on-secondary: '#5a1b00'
  secondary-container: '#ff5e07'
  on-secondary-container: '#531900'
  tertiary: '#f8f4f7'
  on-tertiary: '#303032'
  tertiary-container: '#dbd8db'
  on-tertiary-container: '#5f5e60'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#7df4ff'
  primary-fixed-dim: '#00dbe9'
  on-primary-fixed: '#002022'
  on-primary-fixed-variant: '#004f54'
  secondary-fixed: '#ffdbce'
  secondary-fixed-dim: '#ffb59a'
  on-secondary-fixed: '#370e00'
  on-secondary-fixed-variant: '#802a00'
  tertiary-fixed: '#e4e2e4'
  tertiary-fixed-dim: '#c8c6c8'
  on-tertiary-fixed: '#1b1b1d'
  on-tertiary-fixed-variant: '#474649'
  background: '#121317'
  on-background: '#e3e2e7'
  surface-variant: '#343539'
typography:
  display-speed:
    fontFamily: Inter
    fontSize: 120px
    fontWeight: '700'
    lineHeight: 120px
    letterSpacing: -0.04em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  data-mono-lg:
    fontFamily: JetBrains Mono
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
  data-mono-sm:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.1em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 8px
  container-padding: 32px
  gutter: 16px
  component-gap: 12px
---

## Brand & Style
The design system is engineered for the high-stakes environment of urban transit. The brand personality is clinical, precise, and dependable, prioritizing driver focus and passenger safety. It adopts a **Minimalist-Modern** aesthetic with a specific focus on **Functional Information Density**.

The UI must evoke a sense of calm control. By utilizing expansive dark surfaces, the design system minimizes light pollution within the cabin, ensuring the driver's night vision is preserved. Visual flourishes are strictly reserved for state changes and critical alerts, using a mix of flat surfaces and subtle **Neomorphic** cues to provide tactile affordance without clutter.

## Colors
The palette is optimized for high-contrast legibility against a deep-space background. 

- **Primary (Electric Cyan):** Used for active data streams, speedometers, and "Go" states. It represents the "Electric" core of the shuttle.
- **Secondary (Safety Orange):** Reserved exclusively for warnings, critical battery levels, and immediate action items.
- **Backgrounds:** A tiered system of `#000000` (Pure Black) for the base layer and `#1A1A1C` (Deep Charcoal) for elevated component containers to reduce eye strain.
- **Data Accents:** Subtle glows using the primary color are permitted to indicate system "Ready" states.

## Typography
This design system utilizes **Inter** for all UI controls and narrative text due to its exceptional legibility and tall x-height. For telemetry, battery percentages, and timestamps, **JetBrains Mono** is employed to provide tabular figures, ensuring that numbers do not "jump" or shift horizontally as they update rapidly.

- **Scale:** Large display sizes are prioritized for glanceability at arm's length (the driver's distance from the dashboard).
- **Style:** All labels should be uppercase with increased letter spacing to ensure clarity in low-light conditions.

## Layout & Spacing
The layout follows a **Fixed Grid** model optimized for wide-aspect ratio dashboard displays (typically 21:9 or 16:5). 

- **Safety Zones:** Critical information (Speed, Battery, Gear) is centered or positioned in the direct line of sight. Secondary telemetry (Climate, Media, Route) is placed in peripheral zones.
- **Rhythm:** An 8px linear scale governs all padding and margins. 
- **Touch Targets:** For interactive elements, a minimum touch target of 64px is required to account for vehicle vibration.

## Elevation & Depth
Elevation is communicated through **Tonal Layering** and **Subtle Neomorphism**. 

- **The Base:** The dashboard background is pure black (`#000000`).
- **Surface Containers:** Cards and interactive zones use a deep charcoal (`#1A1A1C`).
- **Interactive Depth:** Buttons use a dual-shadow approach: a soft top-left highlight (10% opacity white) and a bottom-right shadow (pure black) to create a "molded" tactile look.
- **Active States:** Instead of high-elevation shadows, active states are indicated by an inner-glow (Primary Cyan) or a "sunken" neomorphic effect to simulate a physical press.

## Shapes
The design system uses **Soft (0.25rem)** roundedness to maintain a professional, architectural feel. 

- **Standard Elements:** Buttons and small inputs use the base `0.25rem`.
- **Large Containers:** Main data clusters (e.g., the map view or the power meter) use `0.5rem` (`rounded-lg`) to subtly distinguish them from the frame of the screen.
- **Strictness:** Circular shapes are used exclusively for gauges and progress rings to maintain clear visual categorization.

## Components
- **Buttons:** Large, tactile surfaces. Use the neomorphic "extruded" look for default states and "inset" for pressed states. High-contrast Cyan text for primary actions.
- **Gauges:** Circular or semi-circular rings. The "fill" should utilize a subtle outer glow to simulate a physical LED strip.
- **Chips/Status Indicators:** Low-profile, flat backgrounds with a single leading dot. The dot pulses slowly if the status is "Active/Running."
- **Input Fields:** Stepper-style controls (Plus/Minus) are preferred over sliders for precision while driving.
- **Critical Alerts:** Full-width banners at the top of the display using the Safety Orange palette with high-frequency pulsing for "Immediate Stop" scenarios.
- **Lists:** Data-heavy lists (e.g., upcoming stops) should use alternating row opacities and monospaced timestamps.