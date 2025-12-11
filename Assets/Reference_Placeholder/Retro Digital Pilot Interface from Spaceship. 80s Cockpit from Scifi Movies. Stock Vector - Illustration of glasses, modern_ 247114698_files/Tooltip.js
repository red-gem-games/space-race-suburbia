DT.tooltip=(()=>{const FloatingUIDOM=window.FloatingUIDOM;const isVisible=(element)=>{return(document.body.contains(element)&&element.offsetWidth>0&&element.offsetHeight>0)};const isInsideModal=(element)=>{return element.closest('.js-modal-container')!==null};const isMultipleSelector=(selector)=>{return typeof selector==='string'&&selector.indexOf(',')!==-1};const initMultipleSelector=(selector)=>{return selector.split(',').map((selector)=>tooltip(selector.trim(),options))};const tooltip=(selectorOrElement,options={})=>{if(isMultipleSelector(selectorOrElement)){return initMultipleSelector(selectorOrElement)}
const element=DT.getElement(selectorOrElement);return(tooltip.getForElement(element)??new tooltip.Tooltip(element,tooltipManager,options))};const attributePrefix='data-tooltip-';tooltip.Tooltip=class{static template=`
      <div class="tooltip js-tooltip" role="tooltip" data-state="hidden">
        <div class="tooltip__content js-tooltip-content"></div>
      </div>
    `;static arrowTemplate=`
      <div class="tooltip__arrow js-tooltip-arrow"></div>
    `;static defaultAnimationDuration=100;static defaultDelay=100;static elementRemoveIntervalDelay=10000;constructor(element,tooltipManager,{content=null,ariaLabel=null,themes='grey',isInline=!1,classList=[],id=null,animationDuration=tooltip.Tooltip.defaultAnimationDuration,updateAnimation=!0,placement='top',fallbackPlacement='start',fallbackPlacements=null,offset=5,useHeaderOffset=!0,contentAsHtml=!0,closeBehaviour='hide',trigger='hover',triggerOpen={},triggerClose={},delay=tooltip.Tooltip.defaultDelay,trackElementMove=!1,arrow=!0,useShift=!0,interactive=!1,matchElementWidth=!1,elementWidthAsMaxWidth=!1,useAvailabileHeight=!0,maxWidth=null,minWidth=null,maxHeight=null,minHeight=null,destroyOnElementRemove=!0,zIndex=null,hooks:{onInit=[],beforeOpen=[],onOpen=[],afterOpen=[],afterOpenAnimation=[],beforeClose=[],afterClose=[],afterToggle=[],beforeDestroy=[],afterDestroy=[],onContentReady=[],onClick=[],onOriginClick=[],onContentUpdate=[],onStyleArrow=[],onUpdateArrowPosition=null,}={},}){this.$referenceElement=DT.getElement(element);if(!this.$referenceElement)throw new Error('Invalid element');this.tooltipManager=tooltipManager;this.hooks={onInit:this.adaptHook(onInit),beforeOpen:this.adaptHook(beforeOpen),onOpen:this.adaptHook(onOpen),afterOpen:this.adaptHook(afterOpen),afterOpenAnimation:this.adaptHook(afterOpenAnimation),beforeClose:this.adaptHook(beforeClose),afterClose:this.adaptHook(afterClose),afterToggle:this.adaptHook(afterToggle),beforeDestroy:this.adaptHook(beforeDestroy),afterDestroy:this.adaptHook(afterDestroy),onContentReady:this.adaptHook(onContentReady),onContentUpdate:this.adaptHook(onContentUpdate),onClick:this.adaptHook(onClick),onOriginClick:this.adaptHook(onOriginClick),onStyleArrow:this.adaptHook(onStyleArrow),onUpdateArrowPosition,};this.ariaLabel=ariaLabel;this.isInline=isInline;this.animationDuration=animationDuration;this.updateAnimation=updateAnimation;this.fallbackPlacement=fallbackPlacement;this.fallbackPlacements=fallbackPlacements;this.optionClassList=classList;this.optionId=id;this.themes=Array.isArray(themes)?themes:[themes];this.placement=placement;this.offset=offset;this.useHeaderOffset=useHeaderOffset;this.contentAsHtml=contentAsHtml;this.closeBehaviour=closeBehaviour;this.optionsTrigger=trigger;this.optionsTriggerClose={...{click:!1,tap:!1,originClick:!1,scroll:!1,mouseleave:!1,touchleave:!1,referenceHidden:!0,},...triggerClose,};this.optionsTriggerOpen={...{click:!1,mouseenter:!1,touchstart:!1,},...triggerOpen,};this.delay=delay;this.trackElementMove=trackElementMove;this.arrow=arrow;this.interactive=interactive;this.matchElementWidth=matchElementWidth;this.elementWidthAsMaxWidth=elementWidthAsMaxWidth;this.useAvailabileHeight=useAvailabileHeight;this.maxWidth=maxWidth;this.minWidth=minWidth;this.maxHeight=maxHeight;this.minHeight=minHeight;this.destroyOnElementRemove=destroyOnElementRemove;this.zIndex=zIndex;this.useShift=useShift;this.isOpen=!1;this.isOpening=!1;this.isClosing=!1;this.isDestroyed=!1;this.isDestroying=!1;this.onReferenceVisibilityChange=this.onReferenceVisibilityChange.bind(this);this.content=new tooltip.TooltipContent(this,content);this.position=new tooltip.TooltipPosition(this);this.trigger=new tooltip.TooltipTrigger(this);this.previousSequence=null;this.initDelegates();this.tooltipManager.add(this);this.monitorElementRemoveInterval=null;if(this.destroyOnElementRemove)this.monitorElementRemove();this.initAttributeOptions();this.runHook('onInit')}
initAttributeOptions(){if(this.$referenceElement.hasAttribute(`${attributePrefix}themes`)){const themes=this.$referenceElement.getAttribute(`${attributePrefix}themes`);if(themes){this.setThemes(themes.split(',').map((t)=>t.trim()))}}
if(this.$referenceElement.hasAttribute(`${attributePrefix}offset`)){this.offset=parseInt(this.$referenceElement.getAttribute(`${attributePrefix}offset`),10)}
if(this.$referenceElement.hasAttribute(`${attributePrefix}interactive`)){this.interactive=!0}}
adaptHook(hook){return Array.isArray(hook)?hook:[hook]}
addHook(hook,fn){if(!this.hooks[hook])throw new Error(`Hook ${hook} does not exist`);this.hooks[hook].push(fn);return this}
removeHook(hook,fn){if(!this.hooks[hook])throw new Error(`Hook ${hook} does not exist`);this.hooks[hook]=this.hooks[hook].filter((hookFn)=>hookFn!==fn);return this}
runHook(hook,...args){for(const hookFn of this.hooks[hook]){hookFn(this,...args)}}
initDelegates(){Object.defineProperty(this,'$element',{enumerable:!0,get(){return this.content.$element},});Object.defineProperty(this,'$contentElement',{enumerable:!0,get(){return this.content.$contentElement},});Object.defineProperty(this,'$arrowElement',{enumerable:!0,get(){return this.content.$arrowElement},});Object.defineProperty(this,'isContentLoaded',{enumerable:!0,get(){return this.content.isContentLoaded()},});Object.defineProperty(this,'isHidden',{enumerable:!0,get(){return this.content.isHidden()},});this.setStyles=(styles)=>{if(DT.isNullish(styles))return this;this.content.setStyles(styles);return this};this.setContentStyles=(styles)=>{if(DT.isNullish(styles))return this;this.content.setContentStyles(styles);return this};this.setContent=(content,updateAnimation=this.updateAnimation)=>{this.content.setContent(content,!0,updateAnimation);return this};this.resetContent=(updateAnimation)=>{this.content.resetContent(updateAnimation);return this};this.setArrowStyles=(styles)=>{if(!this.$arrowElement)return;this.content.setArrowStyles(styles);return this};this.getThemes=()=>{return this.themes};this.setThemes=(themes)=>{this.content.setThemes(themes);return this};this.addTheme=(theme)=>{this.content.addTheme(theme);return this};this.removeTheme=(theme)=>{this.content.removeTheme(theme);return this};this.setAnimationDuration=(duration)=>{this.tooltip.animationDuration=duration;this.content.setAnimationDuration(duration);return this}}
isAlwaysOpen(){return this.optionsTrigger==='always'}
getAnimationDuration(){return this.animationDuration}
setDelay(delay){this.delay=delay;return this}
getDelay(){return this.delay}
setDestroyOnElementRemove(destroyOnElementRemove){if(this.destroyOnElementRemove===destroyOnElementRemove)return;this.destroyOnElementRemove=destroyOnElementRemove;if(this.destroyOnElementRemove){this.monitorElementRemove()}else{this.stopMonitorElementRemove()}
return this}
monitorElementRemove(){if(!this.destroyOnElementRemove)return;clearInterval(this.monitorElementRemoveInterval);this.monitorElementRemoveInterval=setInterval(()=>{if(this.isDestroyed||this.isDestroying||!this.$referenceElement){return}
if(!document.body.contains(this.$referenceElement)){this.destroy()}},tooltip.Tooltip.elementRemoveIntervalDelay)}
stopMonitorElementRemove(){clearInterval(this.monitorElementRemoveInterval);this.monitorElementRemoveInterval=null}
onReferenceVisibilityChange(isHidden){this.content.onReferenceVisibilityChange(isHidden);if(isHidden){if(this.destroyOnElementRemove&&!document.body.contains(this.$referenceElement)){this.destroy();return}
if(this.trigger.isCloseOnReferenceHidden()){this._close()}
return}
this.open()}
open(){this.trigger.clearScheduled();return this._open()}
close(){this.trigger.clearScheduled();return this._close()}
toggle(){return this.isOpen?this.open():this.close()}
static getLastStartedSequence(sequence){if(!sequence)return null;if(sequence.isStarted)return sequence;while(sequence.previousSequence&&!sequence.previousSequence.isStarted&&!sequence.previousSequence.isFinished){sequence=sequence.previousSequence}
return sequence}
startSequence(fn){this.previousSequence?.abort();const sequence=new tooltip.TransitionSequence(fn,tooltip.Tooltip.getLastStartedSequence(this.previousSequence));this.previousSequence=sequence;sequence.run();return sequence}
async _open({event=null}={}){const sequence=this.startSequence(()=>this.executeOpen({event}));await sequence.run();return sequence.isExecuted&&this.isOpen}
async executeOpen({event=null}={}){if(this.isOpen||this.isOpening||this.isDestroying||this.isDestroyed){return}
if(!document.body.contains(this.$referenceElement)){if(this.destroyOnElementRemove){this.destroy()}
return}
this.isOpening=!0;this.runHook('beforeOpen',event);const showOpen=this.content.open(event);await this.position.start();this.stopMonitorElementRemove();showOpen();this.isOpen=!0;this.isOpening=!1;this.runHook('afterOpen',event);this.runHook('afterToggle',event);return this}
destroy(){this.previousSequence?.abort();if(this.isDestroyed||this.isDestroying)return;this.isDestroying=!0;this.runHook('beforeDestroy');this.trigger.clearScheduled();if(this.isContentLoaded)this.executeClose({isDestroy:!0});this.position.destroy();this.trigger.destroy();this.content.destroy();this.tooltipManager.remove(this);this.stopMonitorElementRemove();this.$referenceElement=null;this.isDestroyed=!0;this.isDestroying=!1;this.runHook('afterDestroy')}
async _close({event=null}={}){const sequence=this.startSequence(()=>this.executeClose({event}));await sequence.run();return sequence.isExecuted&&!this.isOpen}
executeClose({isDestroy=!1,event=null}={}){if(!isDestroy&&(!this.isOpen||this.isClosing||this.isDestroyed||this.isDestroying)){return}
if(this.closeBehaviour==='destroy'&&!isDestroy){this.destroy();return}
this.isClosing=!0;this.runHook('beforeClose',event);this.position.stop();this.monitorElementRemove();switch(this.closeBehaviour){case 'hide':this.content.hide();break;case 'remove':this.content.remove();break}
this.isClosing=!1;this.isOpen=!1;this.runHook('afterClose',event);this.runHook('afterToggle',event);return this}};tooltip.TransitionSequence=class{constructor(fn,previousSequence){this.isStarted=!1;this.isFinished=!1;this.isExecuted=!1;this.fn=fn;this.runPromise=null;this.previousSequence=previousSequence}
abort(){if(this.isFinished)return;this.isFinished=!0}
run(){if(this.runPromise)return this.runPromise;this.runPromise=new Promise(async(resolve)=>{try{if(this.previousSequence){await this.previousSequence.runPromise}
if(this.isFinished){resolve();return}
this.isStarted=!0;await this.fn(this);this.isExecuted=!0}catch(error){DT.log('error','Tooltip sequence run error',error)}finally{this.isFinished=!0;resolve()}});return this.runPromise}};tooltip.TooltipContent=class{constructor(tooltip,content){this.tooltip=tooltip;this.optionsContent=content;this.originalContent=null;this.contentResource=null;this.contentType=null;this.$element=null;this.$contentElement=null;this.onElementClick=this.onElementClick.bind(this);if(DT.isNullish(this.optionsContent)&&!this.tooltip.$referenceElement.hasAttribute(`${attributePrefix}content`)&&!this.tooltip.$referenceElement.hasAttribute('title')){throw new Error(`Missing "${attributePrefix}content" attribute or "title" attribute from reference element when content is not provided`)}
this.initContentResource()}
isContentLoaded(){return this.$element!==null}
setContent(content,isUpdate=!1,updateAnimation=!0){if(!this.isContentLoaded())this.load();if(!this.$contentElement)return;if(this.tooltip.contentAsHtml){this.$contentElement.innerHTML=content}else{this.$contentElement.textContent=content}
if(!isUpdate)return;if(this.tooltip.isOpen&&updateAnimation)this.showAnimation('Update');this.tooltip.runHook('onContentUpdate',this.$contentElement)}
resetContent(updateAnimation=!1){if(!this.isContentLoaded())this.load();this.setContent(this.originalContent,!0,updateAnimation)}
async showAnimation(animationName){if(this.tooltip.animationDuration===0)return;DT.UI.setCustom(this.$element,'anim',animationName.toLowerCase());let animationId=this.generateAnimationId();this.currentAnimationId=animationId;await this.waitForAnimation(`tooltip${animationName}`);if(this.currentAnimationId!==animationId)return!1;DT.UI.unsetCustom(this.$element,'anim');return!0}
destroy(){this.tooltip.tooltipManager.removeTooltipElement(this.tooltip);this.$element?.removeEventListener('click',this.onElementClick);this.$element?.remove();this.$element=null;this.$contentElement=null;this.$arrowElement=null;this.currentAnimationId=null}
generateAnimationId(){return Date.now()}
load(){if(this.isContentLoaded())return;const renderElement=document.createElement('div');renderElement.innerHTML=tooltip.Tooltip.template;this.$element=renderElement.firstElementChild;this.$contentElement=this.$element.firstElementChild;if(this.tooltip.arrow){const arrowElement=document.createElement('div');arrowElement.innerHTML=tooltip.Tooltip.arrowTemplate;this.$arrowElement=arrowElement.firstElementChild;this.$element.appendChild(this.$arrowElement)}
try{const content=this.fetchContent();this.originalContent=content;this.setContent(content);this.initContent()}catch(error){DT.log('error','Error loading tooltip content',error);throw error}}
setThemes(themes){if(this.isContentLoaded()){this.$element.classList.remove(...this.tooltip.themes.map((t)=>`tooltip--${t}`));this.$element.classList.add(...themes.map((t)=>`tooltip--${t}`))}
this.tooltip.themes=themes}
addTheme(theme){if(this.tooltip.themes.includes(theme))return;if(this.isContentLoaded()){this.$element.classList.add(`tooltip--${theme}`)}
this.tooltip.themes.push(theme)}
removeTheme(theme){if(this.isContentLoaded()){this.$element.classList.remove(`tooltip--${theme}`)}
this.tooltip.themes=this.tooltip.themes.filter((t)=>t!==theme)}
setAnimationDuration(duration){if(!this.isContentLoaded())return;if(DT.isNullish(duration)){this.$element.style.removeProperty(`--tooltip-anim-duration`);return}
this.$element.style.setProperty(`--tooltip-anim-duration`,`${duration}ms`)}
handleReferenceInsideModal(){if(!this.isContentLoaded())return;if(isInsideModal(this.tooltip.$referenceElement)){this.$element.classList.add('tooltip--modal')}else{this.$element.classList.remove('tooltip--modal')}}
formatStyleProperty(value){if(!value)return null;return `${value}px`}
initContent(){this.tooltip.tooltipManager.addTooltipElement(this.tooltip);this.$element.classList.add(...this.tooltip.themes.map((t)=>`tooltip--${t}`));this.$element.classList.add(...this.tooltip.optionClassList);if(this.tooltip.optionId)this.$element.id=this.tooltip.optionId;if(this.tooltip.ariaLabel){this.$element.setAttribute('aria-label',this.tooltip.ariaLabel)}
this.setStyles({zIndex:this.tooltip.zIndex,});this.setContentStyles({maxWidth:this.formatStyleProperty(this.tooltip.maxWidth),minWidth:this.formatStyleProperty(this.tooltip.minWidth),maxHeight:this.formatStyleProperty(this.tooltip.maxHeight),minHeight:this.formatStyleProperty(this.tooltip.minHeight),});this.setAnimationDuration(this.tooltip.animationDuration);this.$element.addEventListener('click',this.onElementClick);this.tooltip.runHook('onContentReady')}
onElementClick(event){this.tooltip.runHook('onClick',event)}
setStyles(styles){if(!this.isContentLoaded())return;Object.assign(this.$element.style,styles)}
setContentStyles(styles){if(!this.isContentLoaded())return;Object.assign(this.$contentElement.style,styles)}
setArrowStyles(styles){if(!this.isContentLoaded()||!this.$arrowElement)return;Object.assign(this.$arrowElement.style,styles)}
initContentResource(){if(DT.isNullish(this.optionsContent)){if(this.tooltip.$referenceElement.hasAttribute('title')){this.contentResource=this.tooltip.$referenceElement.getAttribute('title');this.contentType='string';this.tooltip.$referenceElement.removeAttribute('title');return}
const dataContent=this.tooltip.$referenceElement.getAttribute(`${attributePrefix}content`);const element=DT.getElement(dataContent);if(element){this.optionsContent=element}else{this.contentResource=dataContent;this.contentType='string';return}}
if(typeof this.optionsContent==='string'){if(this.optionsContent.startsWith('data-')){this.contentResource=this.tooltip.$referenceElement.getAttribute(this.optionsContent);this.contentType='string';return}
this.contentResource=this.optionsContent;this.contentType='string';return}
if(DT.isElement(this.optionsContent)){if(this.optionsContent instanceof HTMLTemplateElement){this.contentResource=this.optionsContent.content.cloneNode(!0);this.contentType='template';return}
this.contentResource=this.optionsContent.outerHTML;this.contentType='string';return}
if(typeof this.optionsContent==='function'){this.contentResource=this.optionsContent;this.contentType='function';return}
throw new Error('Invalid content type')}
fetchContent(){switch(this.contentType){case 'template':const renderElement=document.createElement('div');renderElement.appendChild(this.contentResource);return renderElement.innerHTML;case 'string':return this.contentResource;case 'function':const content=this.contentResource();if(typeof content!=='string'){throw new Error('Tooltip content function must return a string')}
return content;default:throw new Error(`Unknown content type ${this.contentType}`)}}
open(event=null){if(!this.isContentLoaded())this.load();if(!document.body.contains(this.$element))this.addToDom();this.tooltip.runHook('onOpen',event);this.setStyles({visibility:'hidden'});DT.UI.unset(this.$element,'hidden');this.$element.setAttribute('aria-hidden','false');this.handleReferenceInsideModal();return async()=>{this.setStyles({visibility:null});await this.showAnimation('Open');this.tooltip.runHook('afterOpenAnimation',event)}}
remove(){this.hide();this.$element?.remove()}
hide(withAnimation=!0){if(withAnimation){this.showCloseAnimation()}else{DT.UI.set(this.$element,'hidden')}
this.$element.setAttribute('aria-hidden','true')}
async showCloseAnimation(){if(this.tooltip.animationDuration===0){DT.UI.set(this.$element,'hidden');return}
const isCurrent=await this.showAnimation('Close');if(isCurrent&&!this.isOpen&&!this.isOpening){DT.UI.set(this.$element,'hidden')}}
onReferenceVisibilityChange(isHidden){this.setStyles({visibility:isHidden?'hidden':null,});this.$element.setAttribute('aria-hidden',isHidden?'true':'false')}
waitForAnimation(animation){return new Promise((resolve)=>{this.$element.addEventListener('animationend',(event)=>{if(event.animationName!==animation)return;resolve()},{capture:!1,once:!0,})})}
addToDom(){document.body.appendChild(this.$element)}
isHidden(){return DT.UI.is(this.$element,'hidden')||!isVisible(this.$element)}
isVisibilityHidden(){return this.$element.style.visibility==='hidden'}};tooltip.TooltipPosition=class{static arrowOffset=4;static documentEdgePadding=5;constructor(tooltip){this.tooltip=tooltip;this.referenceHidden=null;this.cleanup=()=>{};this.update=this.update.bind(this);this.handleSize=this.handleSize.bind(this)}
async update(){if(this.tooltip.isHidden||!this.tooltip.$referenceElement)return;try{const documentEdgePadding=tooltip.TooltipPosition.documentEdgePadding;const headerOffset=this.tooltip.useHeaderOffset?this.getHeaderOffset():0;const position=await FloatingUIDOM.computePosition(this.tooltip.$referenceElement,this.tooltip.$element,{placement:this.tooltip.placement,middleware:[FloatingUIDOM.offset(({placement})=>{if(!DT.isObject(this.tooltip.offset)){return this.tooltip.offset}
const offset=this.tooltip.offset[placement]??this.tooltip.offset.default??5;return offset}),this.tooltip.isInline&&FloatingUIDOM.inline(),FloatingUIDOM.flip({fallbackAxisSideDirection:this.tooltip.fallbackPlacement,crossAxis:!1,fallbackPlacements:this.tooltip.fallbackPlacements,padding:{top:headerOffset,},}),this.tooltip.useShift&&FloatingUIDOM.shift({limiter:FloatingUIDOM.limitShift(),padding:{top:headerOffset||documentEdgePadding,right:documentEdgePadding,bottom:documentEdgePadding,left:documentEdgePadding,},}),this.tooltip.arrow&&FloatingUIDOM.arrow({element:this.tooltip.$arrowElement,}),FloatingUIDOM.size({padding:{top:headerOffset,},apply:this.handleSize,}),this.rectsMiddleware(),FloatingUIDOM.hide({padding:{top:headerOffset,},}),],});this.updatePosition(position)}catch(error){DT.log('error','Tooltip update position error',this,error)}}
rectsMiddleware(){return{name:'rects',fn:({rects})=>{return{data:rects,}},}}
getHeaderOffset(){if(isInsideModal(this.tooltip.$referenceElement)){return 0}
return DT.getHeaderOffset()}
handleSize({rects,availableHeight}){if(this.tooltip.elementWidthAsMaxWidth){this.tooltip.setContentStyles({maxWidth:`${rects?.reference?.width}px`,})}
if(this.tooltip.matchElementWidth){this.tooltip.setContentStyles({width:`${rects?.reference?.width}px`,})}
if(this.tooltip.useAvailabileHeight&&availableHeight){this.tooltip.setContentStyles({maxHeight:`${availableHeight}px`,})}}
updatePosition(position){const{x,y,placement,middlewareData}=position;this.tooltip.$element.setAttribute('data-placement',placement);this.tooltip.setStyles({top:`${y}px`,left:`${x}px`,});if(this.tooltip.arrow){this.updateArrowPosition({x:middlewareData.arrow.x,y:middlewareData.arrow.y,centerOffset:middlewareData.arrow.centerOffset,placement,rects:middlewareData.rects,})}
const{referenceHidden}=middlewareData.hide;if(this.referenceHidden===null){this.referenceHidden=referenceHidden;return}
if(referenceHidden!==this.referenceHidden){this.tooltip.onReferenceVisibilityChange(referenceHidden);this.referenceHidden=referenceHidden}}
updateArrowPosition({x,y,placement,centerOffset,rects}){const staticSide={top:'bottom',right:'left',bottom:'top',left:'right',}[placement.split('-')[0]];let finalX=x;let finalY=y;let arrowOffset=tooltip.TooltipPosition.arrowOffset;if(this.tooltip.hooks.onUpdateArrowPosition){const position=this.tooltip.hooks.onUpdateArrowPosition(this.tooltip,{x,y,placement,arrowOffset,});if(position?.x!==undefined){finalX=position.x}
if(position?.y!==undefined){finalY=position.y}
if(position?.arrowOffset!==undefined){arrowOffset=position.arrowOffset}}
this.tooltip.setArrowStyles({left:finalX!=null?`${finalX}px`:'',top:finalY!=null?`${finalY}px`:'',right:'',bottom:'',[staticSide]:`-${arrowOffset}px`,});this.tooltip.runHook('onStyleArrow',{placement,x:finalX,y:finalY,arrowOffset,rects,arrow:this.tooltip.$arrowElement,reference:this.tooltip.$referenceElement,isCentered:centerOffset===0,})}
async start(){this.cleanup();await this.update();this.cleanup=FloatingUIDOM.autoUpdate(this.tooltip.$referenceElement,this.tooltip.$element,this.update,{animationFrame:this.tooltip.trackElementMove,})}
stop(){this.cleanup()}
destroy(){this.stop()}};tooltip.TooltipTrigger=class{constructor(tooltip){this.tooltip=tooltip;if(!['click','hover','custom','always'].includes(this.tooltip.optionsTrigger)){throw new Error(`Invalid trigger option ${this.tooltip.optionsTrigger}. Must be one of
          'click', 'hover', 'custom'`)}
if(this.tooltip.optionsTrigger==='click'){this.tooltip.optionsTriggerOpen.click=!0;this.tooltip.optionsTriggerClose.click=!0}
if(this.tooltip.optionsTrigger==='hover'){this.tooltip.optionsTriggerOpen.mouseenter=!0;this.tooltip.optionsTriggerOpen.touchstart=!0;this.tooltip.optionsTriggerClose.mouseleave=!0;this.tooltip.optionsTriggerClose.touchleave=!0}
this.handleOriginClick=null;this.updateOnOriginClick=this.updateOnOriginClick.bind(this);this.onOpenHoverStart=this.onOpenHoverStart.bind(this);this.onOriginClick=this.onOriginClick.bind(this);this.onOpenClick=this.onOpenClick.bind(this);this.onCloseHoverEnd=this.onCloseHoverEnd.bind(this);this.onCloseClick=this.onCloseClick.bind(this);this.onCloseOriginClick=this.onCloseOriginClick.bind(this);this.onCloseScroll=this.onCloseScroll.bind(this);this.onCloseTap=this.onCloseTap.bind(this);this.onClosePointerLeave=this.onClosePointerLeave.bind(this);this.isTooltipHover=!1;this.onTooltipPointerEnter=this.onTooltipPointerEnter.bind(this);this.onTooltipPointerLeave=this.onTooltipPointerLeave.bind(this);this.onTouchEnd=this.onTouchEnd.bind(this);this.initTooltipListeners=this.initTooltipListeners.bind(this);this.afterLazyLoadHoverCheck=this.afterLazyLoadHoverCheck.bind(this);this.allowHover=this.allowHover.bind(this);this.scheduledOpen=null;this.scheduledClose=null;this.tooltip.addHook('onContentReady',this.initTooltipListeners);this.tooltip.addHook('afterToggle',this.updateOnOriginClick);this.tooltip.addHook('afterOpenAnimation',this.afterLazyLoadHoverCheck);if(this.tooltip.isAlwaysOpen()){this.tooltip.addHook('onInit',()=>{this.tooltip.open()})}
this.init()}
isCloseOnReferenceHidden(){if(this.tooltip.isAlwaysOpen()){return!1}
return this.tooltip.optionsTriggerClose.referenceHidden}
init(){this.removeListeners();this.initGeneralListeners();this.initOpenTriggers();this.initCloseTriggers();this.updateOnOriginClick();if(this.tooltip.$element)this.initTooltipListeners();}
removeListeners(){this.clearScheduled();this.removeGeneralListeners();this.removeOpenTriggers();this.removeCloseTriggers();this.removeTooltipListeners()}
initGeneralListeners(){this.tooltip.$referenceElement.addEventListener('click',this.onOriginClick,{passive:!1})}
removeGeneralListeners(){this.tooltip.$referenceElement.removeEventListener('click',this.onOriginClick,{passive:!1})}
scheduleOpen(fn){this.clearScheduledOpen();if(this.tooltip.delay===0){fn();return}
this.scheduledOpen=setTimeout(()=>{fn();this.scheduledOpen=null},this.tooltip.delay)}
scheduleClose(fn){this.clearScheduledClose();if(this.tooltip.delay===0){fn();return}
this.scheduledClose=setTimeout(()=>{fn();this.scheduledClose=null},this.tooltip.delay)}
clearScheduledOpen(){clearTimeout(this.scheduledOpen);this.scheduledOpen=null}
clearScheduledClose(){clearTimeout(this.scheduledClose);this.scheduledClose=null}
clearScheduled(){this.clearScheduledOpen();this.clearScheduledClose()}
initOpenTriggers(){if(this.tooltip.optionsTriggerOpen.mouseenter){this.tooltip.$referenceElement.addEventListener('mouseenter',this.onOpenHoverStart,{passive:!0})}
if(this.tooltip.optionsTriggerOpen.touchstart&&DT.isTouchDevice){this.tooltip.$referenceElement.addEventListener('touchstart',this.onOpenHoverStart,{passive:!0})}}
removeOpenTriggers(){if(!this.tooltip.$referenceElement)return;this.tooltip.$referenceElement.removeEventListener('mouseenter',this.onOpenHoverStart,{passive:!0});this.tooltip.$referenceElement.removeEventListener('touchstart',this.onOpenHoverStart,{passive:!0})}
initCloseTriggers(){if(this.tooltip.optionsTriggerClose.click){tooltip.TriggerGlobalListeners.addListener('click',this.onCloseClick)}
if(this.tooltip.optionsTriggerClose.mouseleave){this.tooltip.$referenceElement.addEventListener('mouseleave',this.onCloseHoverEnd,{passive:!0})}
if(this.tooltip.optionsTriggerClose.touchleave&&DT.isTouchDevice){this.tooltip.$referenceElement.addEventListener('pointerleave',this.onClosePointerLeave,{passive:!0});this.tooltip.$referenceElement.addEventListener('pointercancel',this.onCloseHoverEnd,{passive:!0})}
if(this.tooltip.optionsTriggerClose.scroll){tooltip.TriggerGlobalListeners.addListener('scroll',this.onCloseScroll);this.initAncestorsOnScroll()}
if(this.tooltip.optionsTriggerClose.tap&&DT.isTouchDevice){tooltip.TriggerGlobalListeners.addListener('tap',this.onCloseTap)}
if(this.tooltip.optionsTriggerClose.touchleave&&DT.isTouchDevice){tooltip.TriggerGlobalListeners.addListener('touchend',this.onTouchEnd);tooltip.TriggerGlobalListeners.addListener('touchcancel',this.onTouchEnd)}}
removeCloseTriggers(){this.tooltip.$referenceElement?.removeEventListener('mouseleave',this.onCloseHoverEnd,{passive:!0});tooltip.TriggerGlobalListeners.removeListener('click',this.onCloseClick);this.tooltip.$referenceElement?.removeEventListener('pointerleave',this.onClosePointerLeave,{passive:!0});this.tooltip.$referenceElement?.removeEventListener('pointercancel',this.onCloseHoverEnd,{passive:!0});tooltip.TriggerGlobalListeners.removeListener('scroll',this.onCloseScroll);this.removeAncestorsOnScroll();tooltip.TriggerGlobalListeners.removeListener('tap',this.onCloseTap);tooltip.TriggerGlobalListeners.removeListener('touchend',this.onTouchEnd);tooltip.TriggerGlobalListeners.removeListener('touchcancel',this.onTouchEnd)}
initAncestorsOnScroll(){const ancestors=this.getAncestors(this.tooltip.$referenceElement);for(const ancestor of ancestors){ancestor.addEventListener('scroll',this.onCloseScroll,{passive:!0,})}}
removeAncestorsOnScroll(){if(!this.tooltip.$referenceElement)return;const ancestors=this.getAncestors(this.tooltip.$referenceElement);for(const ancestor of ancestors){ancestor.removeEventListener('scroll',this.onCloseScroll,{passive:!0,})}}
initTooltipListeners(){if(DT.isTouchDevice)return;this.tooltip.$element.addEventListener('pointerenter',this.onTooltipPointerEnter,{passive:!0,});this.tooltip.$element.addEventListener('pointerleave',this.onTooltipPointerLeave,{passive:!0,});this.tooltip.$element.addEventListener('pointercancel',this.onTooltipPointerLeave,{passive:!0,})}
removeTooltipListeners(){if(!this.tooltip.isContentLoaded||DT.isTouchDevice)return;this.tooltip.$element?.removeEventListener('pointerenter',this.onTooltipPointerEnter,{passive:!0,});this.tooltip.$element?.removeEventListener('pointerleave',this.onTooltipPointerLeave,{passive:!0,});this.tooltip.$element?.removeEventListener('pointercancel',this.onTooltipPointerLeave,{passive:!0})}
onTooltipPointerEnter(event){if(!this.tooltip.$element||!this.isContainedInTooltip(event.target)){return}
this.isTooltipHover=!0}
onTooltipPointerLeave(event){if(!this.tooltip.$element||!this.isContainedInTooltip(event.target)){return}
this.isTooltipHover=!1;if(this.tooltip.optionsTriggerClose.mouseleave||this.tooltip.optionsTriggerClose.touchleave){this.onCloseHoverEnd(event)}}
async onTouchEnd(event){await DT.Scheduler.waitForMediumPriority();if(!this.tooltip.$element||this.isContainedInReference(event.target))
return;try{let isTooltipHover=!1;for(const touch of event.changedTouches){const hoveredElement=document.elementFromPoint(touch.clientX,touch.clientY);isTooltipHover=this.isContainedInTooltip(hoveredElement);if(isTooltipHover)break}
this.isTooltipHover=isTooltipHover}catch(_){this.isTooltipHover=!1}
if(this.tooltip.optionsTriggerClose.touchleave){this.onCloseHoverEnd(event)}}
destroy(){this.removeListeners()}
isContainedInTooltip(element){return this.tooltip.$element?.contains(element)??!1}
isContainedInReference(element){return this.tooltip.$referenceElement?.contains(element)??!1}
getAncestors(element){const ancestors=[];while(element&&element!==document.body){ancestors.push(element);element=element.parentElement}
return ancestors}
onOpenClick(event){this.clearScheduled();this.tooltip._open({event})}
onOpenHoverStart(event){this.clearScheduled();if(this.tooltip.delay===0){this.tooltip._open({event});return}
this.scheduleOpen(()=>{this.tooltip._open({event})})}
allowHover(){if(this.tooltip.interactive)return!0;const isScrollable=this.tooltip.$contentElement?.scrollHeight>this.tooltip.$contentElement?.clientHeight||this.tooltip.$contentElement?.scrollWidth>this.tooltip.$contentElement?.clientWidth;return isScrollable}
onCloseClick(event){if(this.tooltip.interactive&&this.isContainedInTooltip(event.target)){return}
if(this.isContainedInReference(event.target))return;this.clearScheduled();this.tooltip._close({event})}
onCloseOriginClick(event){this.clearScheduled();this.tooltip._close({event})}
onOriginClick(event){this.tooltip.runHook('onOriginClick',event);this.handleOriginClick?.(event)}
updateOnOriginClick(){if(this.tooltip.optionsTriggerOpen.click&&!this.tooltip.isOpen){this.handleOriginClick=this.onOpenClick;return}
if(this.tooltip.optionsTriggerClose.originClick&&this.tooltip.isOpen){this.handleOriginClick=this.onCloseOriginClick;return}
this.handleOriginClick=null}
onCloseTap(event){if(this.tooltip.interactive&&this.isContainedInTooltip(event.target)){return}
this.clearScheduled();this.tooltip._close({event})}
onClosePointerLeave(event){if(!event.relatedTarget||this.isContainedInReference(event.relatedTarget)){return}
return this.onCloseHoverEnd(event)}
onCloseHoverEnd(event){if(this.isTooltipHover&&this.allowHover())return;this.clearScheduled();if(this.tooltip.delay===0){this.tooltip._close({event});return}
this.scheduleClose(()=>{if(this.isTooltipHover&&this.allowHover())return;this.tooltip._close({event})})}
onCloseScroll(event){this.clearScheduled();this.tooltip._close({event})}
afterLazyLoadHoverCheck(){this.tooltip.removeHook('afterOpen',this.afterLazyLoadHoverCheck);if(!this.tooltip.isOpen||!this.tooltip.optionsTriggerOpen.mouseenter||!this.tooltip.optionsTriggerClose.mouseleave){return}
const hoveredElements=[...document.querySelectorAll(':hover')];const lastHoveredElement=hoveredElements[hoveredElements.length-1];if(!lastHoveredElement){this.tooltip._close();return}
if(this.tooltip.$referenceElement?.contains(lastHoveredElement))return;if(this.allowHover()&&this.tooltip.$element?.contains(lastHoveredElement)){return}
this.tooltip._close()}};tooltip.TriggerGlobalListeners=new(class{constructor(){this.listenersRegistry=new Map();this.listeners={click:{init:()=>{this.onClick=this.onClick.bind(this)},add:()=>{document.addEventListener('click',this.onClick,{passive:!0,})},remove:()=>{document.removeEventListener('click',this.onClick,{passive:!0,})},},scroll:{init:()=>{this.onScroll=DT.debounce(this.onScroll.bind(this),250)},add:()=>{document.addEventListener('scroll',this.onScroll,{passive:!0,})},remove:()=>{document.removeEventListener('scroll',this.onScroll,{passive:!0,})},},touchend:{init:()=>{this.onTouchEnd=this.onTouchEnd.bind(this)},add:()=>{document.addEventListener('touchend',this.onTouchEnd,{passive:!0,})},remove:()=>{document.removeEventListener('touchend',this.onTouchEnd,{passive:!0,})},},touchcancel:{init:()=>{this.onTouchCancel=this.onTouchCancel.bind(this)},add:()=>{document.addEventListener('touchcancel',this.onTouchCancel,{passive:!0,})},remove:()=>{document.removeEventListener('touchcancel',this.onTouchCancel,{passive:!0,})},},tap:{init:()=>{this.isTapCandidate=!1;this.onTouchStart=this.onTouchStart.bind(this);this.onTouchMove=this.onTouchMove.bind(this);this.onTouchEnd=this.onTouchEnd.bind(this)},add:()=>{document.addEventListener('touchstart',this.onTouchStart,{passive:!0,});document.addEventListener('touchmove',this.onTouchMove,{passive:!0,});document.addEventListener('touchend',this.onTouchEnd,{passive:!0,})},remove:()=>{document.removeEventListener('touchstart',this.onTouchStart,{passive:!0,});document.removeEventListener('touchmove',this.onTouchMove,{passive:!0,});document.removeEventListener('touchend',this.onTouchEnd,{passive:!0,})},},};for(const key in this.listeners){this.listeners[key].init()}}
addListener(key,listener){if(!this.listenersRegistry.has(key)){this.listeners[key].add();this.listenersRegistry.set(key,[])}
this.listenersRegistry.get(key).push(listener)}
removeListener(key,listener){if(!this.listenersRegistry.has(key))return;let listeners=this.listenersRegistry.get(key);listeners=listeners.filter((l)=>l!==listener);if(listeners.length===0){this.listeners[key].remove();this.listenersRegistry.delete(key);return}
this.listenersRegistry.set(key,listeners)}
runListeners(key,...args){if(!this.listenersRegistry.has(key))return;const listeners=this.listenersRegistry.get(key);for(const listener of listeners){listener(...args)}}
onTouchStart(){this.isTapCandidate=!0}
onTouchMove(){this.isTapCandidate=!1}
onTouchEnd(event){this.runListeners('touchend',event);if(!this.isTapCandidate)return;this.isTapCandidate=!1;this.runListeners('tap',event)}
onTouchCancel(event){this.runListeners('touchcancel',event)}
onClick(event){this.runListeners('click',event)}
onScroll(event){this.runListeners('scroll',event)}})();tooltip.TooltipManager=class{constructor(){this.tooltips=new WeakMap();this.tooltipsElement=new WeakMap()}
add(tooltip){this.tooltips.set(tooltip.$referenceElement,tooltip);if(tooltip.$element){this.tooltipsElement.set(tooltip.$element,tooltip)}}
addTooltipElement(tooltip){this.tooltipsElement.set(tooltip.$element,tooltip)}
remove(tooltip){if(tooltip.$referenceElement){this.tooltips.delete(tooltip.$referenceElement)}
if(tooltip.$element){this.tooltipsElement.delete(tooltip.$element,tooltip)}}
removeTooltipElement(tooltip){if(!tooltip.$element)return;this.tooltipsElement.delete(tooltip.$element)}
getForElement(element){return this.tooltips.get(element)}
has(element){return this.tooltips.has(element)}
getForTooltipElement(element){return this.tooltipsElement.get(element)}};const tooltipManager=new tooltip.TooltipManager();tooltip.getForElement=tooltipManager.getForElement.bind(tooltipManager);tooltip.getForTooltipElement=tooltipManager.getForTooltipElement.bind(tooltipManager);tooltip.has=tooltipManager.has.bind(tooltipManager);return tooltip})()