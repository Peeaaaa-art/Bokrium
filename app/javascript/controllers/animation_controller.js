import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const animated = this.element.querySelectorAll('.fade-in, .slide-in')

    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.style.animationPlayState = 'running'
          observer.unobserve(entry.target)
        }
      })
    }, { threshold: 0.2 })

    animated.forEach(el => {
      el.style.animationPlayState = 'paused'
      observer.observe(el)
    })
  }
}