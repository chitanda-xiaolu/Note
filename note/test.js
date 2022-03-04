function foo({x, y = 5} = {}) {
  console.log(x, y);
}

foo({x: 1, y: 2}) // undefined 