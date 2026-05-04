const test = require("node:test");
const assert = require("node:assert/strict");

const { calculateMetrics } = require("../src/calculations");

test("calculateMetrics returns expected values", () => {
  const result = calculateMetrics({
    weightKg: 70,
    heightCm: 175,
    age: 30,
    sex: "male",
    activity: "moderate",
  });

  assert.equal(result.bmi, 22.9);
  assert.equal(result.bmiCategory, "Normal");
  assert.equal(result.bmr, 1649);
  assert.equal(result.dailyCalories, 2556);
});
