const PI_CLASSES = [
  { cls: 'A', color: '#C41E1E', min: 235 },
  { cls: 'B', color: '#f97316', min: 165 },
  { cls: 'C', color: '#22c55e', min: 100 },
  { cls: 'D', color: '#2563eb', min: 0 }
]

export function piInfo(value) {
  const n = parseInt(value, 10)
  const entry = isNaN(n) ? null : PI_CLASSES.find(p => n >= p.min)
  return entry ?? PI_CLASSES[3]
}
