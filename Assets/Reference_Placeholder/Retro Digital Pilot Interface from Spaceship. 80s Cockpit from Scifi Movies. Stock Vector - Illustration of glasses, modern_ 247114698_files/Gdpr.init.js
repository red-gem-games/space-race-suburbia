DT.onReady(async()=>{if(DT.afterLcp)await DT.afterLcp?.();const template=`
        <div class="gdpr js-gdpr">
            <div class="gdpr__content">
                For purposes such as displaying personalized ads, we use cookies or similar technologies. By clicking Accept or continuing to browse, you agree to allow the collection of information through cookies or similar technologies. Learn more in the <a href="${site_adr}privacy" rel="nofollow">Privacy Policy</a> section and in <a href="${site_adr}terms#model" rel="nofollow">Terms of Service</a>.
            </div>
            <div class="gdpr__actions">
                <button class="gdpr__refuse btn btn--big js-gdpr-refuse">Refuse all</button>
                <button class="gdpr__accept btn btn--big js-gdpr-accept">Accept all</button>
            </div>
        </div>
    `;const container=document.querySelector('.js-gdpr-container');container?.insertAdjacentHTML('beforeend',template)})