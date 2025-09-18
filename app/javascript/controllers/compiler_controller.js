import { Controller } from "@hotwired/stimulus"
import debounce from "debounce"

export default class extends Controller {
  static targets = ["source", "output", "languageSelect"]

  initialize() {
    this.compileDebounced = debounce(this.compile, 1500).bind(this)
  }

  compile() {
    this.outputTarget.innerHTML = `<pre class="w-full h-full bg-gray-900 rounded font-mono p-2 overflow-auto">Compilando...</pre>`
    this.element.requestSubmit()
  }

  async changeLanguage() {
    const language = this.languageSelectTarget.value
    const response = await fetch(`/hello_world?language=${language}`)
    this.sourceTarget.value = await response.text()
    this.compile()
  }
}