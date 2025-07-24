import { Controller } from "@hotwired/stimulus"

export default class AnimationController extends Controller {
  connect(): void {
    const animatedElements = this.element.querySelectorAll<HTMLElement>('.fade-in, .slide-in')

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const target = entry.target as HTMLElement
            target.style.animationPlayState = 'running'
            observer.unobserve(target)
          }
        })
      },
      { threshold: 0.2 }
    )

    animatedElements.forEach((el) => {
      el.style.animationPlayState = 'paused'
      observer.observe(el)
    })
  }
}