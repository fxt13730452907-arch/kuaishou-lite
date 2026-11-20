var style = document.createElement('style');
style.innerHTML = 'aside, .sidebar, header, .header, .download-bar { display: none !important; } body { touch-action: none !important; overflow: hidden !important; background: #000; } video { width: 100vw !important; height: 100vh !important; object-fit: cover !important; } ::-webkit-scrollbar { display: none !important; }';
document.head.appendChild(style);

function forceUnmute() {
    var videos = document.querySelectorAll('video');
    for (var i = 0; i < videos.length; i++) {
        videos[i].muted = false;
        videos[i].play().catch(function(e) {});
    }
}
forceUnmute();
document.addEventListener('touchstart', forceUnmute, { once: true });
setInterval(forceUnmute, 1500);

var startY = 0;
var isScrolling = false;

document.addEventListener('touchstart', function(e) {
    startY = e.touches[0].clientY;
}, {passive: false});

document.addEventListener('touchmove', function(e) {
    if (Math.abs(e.touches[0].clientY - startY) > 10) {
        e.preventDefault(); 
    }
}, {passive: false});

document.addEventListener('touchend', function(e) {
    var endY = e.changedTouches[0].clientY;
    var distance = startY - endY;
    
    if (Math.abs(distance) > 40 && !isScrolling) {
        isScrolling = true;
        var direction = distance > 0 ? 1 : -1;
        
        var centerX = window.innerWidth / 2;
        var centerY = window.innerHeight / 2;
        var target = document.elementFromPoint(centerX, centerY) || document.body;
        
        var wheelEvent = new WheelEvent('wheel', {
            deltaY: direction * 1000,
            bubbles: true,
            cancelable: true,
            clientX: centerX,
            clientY: centerY
        });
        target.dispatchEvent(wheelEvent);
        window.scrollBy({ top: direction * window.innerHeight * 0.8, behavior: 'smooth' });

        setTimeout(function() { 
            isScrolling = false; 
            forceUnmute(); 
        }, 500);
    }
}, {passive: false});
