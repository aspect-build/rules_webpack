import { load } from 'js-yaml'

export function print() {
  const yaml = load(`
    - test: 2sdsdsd
    `)

  document.querySelector('pre').innerText = JSON.stringify(yaml)
}
