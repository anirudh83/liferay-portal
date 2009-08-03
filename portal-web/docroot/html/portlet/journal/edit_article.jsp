<%
/**
 * Copyright (c) 2000-2009 Liferay, Inc. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
%>

<%@ include file="/html/portlet/journal/init.jsp" %>

<%
String portletResource = ParamUtil.getString(request, "portletResource");

String tabs2 = ParamUtil.getString(request, "tabs2");

String redirect = ParamUtil.getString(request, "redirect");

// Make sure the redirect is correct. This is a workaround for a layout that
// has both the Journal and Journal Content portlets and the user edits an
// article through the Journal Content portlet and then hits cancel.

/*if (redirect.indexOf("p_p_id=" + PortletKeys.JOURNAL_CONTENT) != -1) {
	if (layoutTypePortlet.hasPortletId(PortletKeys.JOURNAL)) {
		PortletURL portletURL = renderResponse.createRenderURL();

		portletURL.setWindowState(WindowState.NORMAL);
		portletURL.setPortletMode(PortletMode.VIEW);

		redirect = portletURL.toString();
	}
}*/

String originalRedirect = ParamUtil.getString(request, "originalRedirect", StringPool.BLANK);

if (originalRedirect.equals(StringPool.BLANK)) {
	originalRedirect = redirect;
}
else {
	redirect = originalRedirect;
}

String referringPortletResource = ParamUtil.getString(request, "referringPortletResource");

JournalArticle article = (JournalArticle)request.getAttribute(WebKeys.JOURNAL_ARTICLE);

long groupId = BeanParamUtil.getLong(article, request, "groupId", scopeGroupId);

String articleId = BeanParamUtil.getString(article, request, "articleId");
String newArticleId = ParamUtil.getString(request, "newArticleId");
String instanceIdKey = PwdGenerator.KEY1 + PwdGenerator.KEY2 + PwdGenerator.KEY3;

double version = BeanParamUtil.getDouble(article, request, "version", JournalArticleImpl.DEFAULT_VERSION);
boolean incrementVersion = ParamUtil.getBoolean(request, "incrementVersion");

Calendar displayDate = CalendarFactoryUtil.getCalendar(timeZone, locale);

if (article != null) {
	if (article.getDisplayDate() != null) {
		displayDate.setTime(article.getDisplayDate());
	}
}

boolean neverExpire = ParamUtil.getBoolean(request, "neverExpire", true);

Calendar expirationDate = CalendarFactoryUtil.getCalendar(timeZone, locale);

expirationDate.add(Calendar.YEAR, 1);

if (article != null) {
	if (article.getExpirationDate() != null) {
		neverExpire = false;

		expirationDate.setTime(article.getExpirationDate());
	}
}

boolean neverReview = ParamUtil.getBoolean(request, "neverReview", true);

Calendar reviewDate = CalendarFactoryUtil.getCalendar(timeZone, locale);

reviewDate.add(Calendar.MONTH, 9);

if (article != null) {
	if (article.getReviewDate() != null) {
		neverReview = false;

		reviewDate.setTime(article.getReviewDate());
	}
}

String type = BeanParamUtil.getString(article, request, "type", "general");

String structureId = BeanParamUtil.getString(article, request, "structureId");

JournalStructure structure = null;

String structureName = LanguageUtil.get(pageContext, "default");

String structureDescription = StringPool.BLANK;

String structureXSD = StringPool.BLANK;

String parentStructureId = StringPool.BLANK;

if (Validator.isNotNull(structureId)) {
	try {
		structure = JournalStructureLocalServiceUtil.getStructure(groupId, structureId);

		structureName = structure.getName();

		structureDescription = structure.getDescription();

		structureXSD = structure.getMergedXsd();

		parentStructureId = structure.getParentStructureId();
	}
	catch (NoSuchStructureException nsse) {
	}
}

List templates = new ArrayList();

if (structure != null) {
	templates = JournalTemplateLocalServiceUtil.getStructureTemplates(groupId, structureId);
}

String templateId = BeanParamUtil.getString(article, request, "templateId");

if ((structure == null) && Validator.isNotNull(templateId)) {
	JournalTemplate template = null;

	try {
		template = JournalTemplateLocalServiceUtil.getTemplate(groupId, templateId);

		structureId = template.getStructureId();

		structure = JournalStructureLocalServiceUtil.getStructure(groupId, structureId);

		structureName = structure.getName();

		templates = JournalTemplateLocalServiceUtil.getStructureTemplates(groupId, structureId);
	}
	catch (NoSuchTemplateException nste) {
	}
}

String languageId = LanguageUtil.getLanguageId(request);

String defaultLanguageId = ParamUtil.getString(request, "defaultLanguageId");

if (article == null) {
	defaultLanguageId = languageId;
}
else {
	if (Validator.isNull(defaultLanguageId)) {
		defaultLanguageId =	article.getDefaultLocale();
	}
}

Locale defaultLocale = LocaleUtil.fromLanguageId(defaultLanguageId);

String content = null;

if (article != null) {
	content = ParamUtil.getString(request, "content");

	if (Validator.isNull(content)) {
		content = article.getContent();
	}

	content = JournalArticleImpl.getContentByLocale(content, Validator.isNotNull(structureId), languageId);
}
else {
	content = ParamUtil.getString(request, "content");
}

Document contentDoc = null;

String[] availableLocales = null;

if (Validator.isNotNull(content)) {
	try {
		contentDoc = SAXReaderUtil.read(content);

		Element contentEl = contentDoc.getRootElement();

		availableLocales = StringUtil.split(contentEl.attributeValue("available-locales"));

		if (structure == null) {
			content = contentDoc.getRootElement().element("static-content").getTextTrim();
		}
	}
	catch (Exception e) {
		contentDoc = null;
	}
}

boolean disableIncrementVersion = false;

if (PropsValues.JOURNAL_ARTICLE_FORCE_INCREMENT_VERSION) {
	boolean latestVersion = (article == null) || (article != null && JournalArticleLocalServiceUtil.isLatestVersion(article.getGroupId(), articleId, version));

	if (!latestVersion) {
		incrementVersion = true;
		disableIncrementVersion = true;
	}

	if ((article != null) && article.isApproved()) {
		incrementVersion = true;
		disableIncrementVersion = true;
	}
}

boolean smallImage = BeanParamUtil.getBoolean(article, request, "smallImage");
String smallImageURL = BeanParamUtil.getString(article, request, "smallImageURL");

String editorImpl = PropsUtil.get(EDITOR_WYSIWYG_IMPL_KEY);

String doAsUserId = themeDisplay.getDoAsUserId();

if (Validator.isNull(doAsUserId)) {
	doAsUserId = Encryptor.encrypt(company.getKeyObj(), String.valueOf(themeDisplay.getUserId()));
}
%>

<script type="text/javascript">
	var <portlet:namespace />count = 0;
	var <portlet:namespace />documentLibraryInput = null;
	var <portlet:namespace />imageGalleryInput = null;
	var <portlet:namespace />contentChangedFlag = false;

	function <portlet:namespace />changeVersionView(version) {
		location.href = "<liferay-portlet:renderURL windowState="<%= WindowState.MAXIMIZED.toString() %>"><portlet:param name="struts_action" value="/journal/edit_article" /><portlet:param name="redirect" value="<%= redirect %>" /><portlet:param name="groupId" value="<%= String.valueOf(groupId) %>" /><portlet:param name="articleId" value="<%= articleId %>" /></liferay-portlet:renderURL>&<portlet:namespace />version=" + version;
	}

	function <portlet:namespace />contentChanged() {
		<portlet:namespace />contentChangedFlag = true;
	}

	function <portlet:namespace />deleteArticle() {
		if (confirm("<%= UnicodeLanguageUtil.get(pageContext, "are-you-sure-you-want-to-deactivate-this") %>")) {
			document.<portlet:namespace />fm1.<portlet:namespace /><%= Constants.CMD %>.value = "<%= Constants.DELETE %>";
			submitForm(document.<portlet:namespace />fm1);
		}
	}

	function <portlet:namespace />disableInputDate(date, checked) {
		document.<portlet:namespace />fm1["<portlet:namespace />" + date + "Month"].disabled = checked;
		document.<portlet:namespace />fm1["<portlet:namespace />" + date + "Day"].disabled = checked;
		document.<portlet:namespace />fm1["<portlet:namespace />" + date + "Year"].disabled = checked;
		document.<portlet:namespace />fm1["<portlet:namespace />" + date + "Hour"].disabled = checked;
		document.<portlet:namespace />fm1["<portlet:namespace />" + date + "Minute"].disabled = checked;
		document.<portlet:namespace />fm1["<portlet:namespace />" + date + "AmPm"].disabled = checked;

		jQuery(document.<portlet:namespace />fm1["<portlet:namespace />" + date + "ImageInputIdInput"]).toggleClass('disabled');
	}

	function <portlet:namespace />editorContentChanged(text) {
		<portlet:namespace />contentChanged();
	}

	function <portlet:namespace />expireArticle() {
		document.<portlet:namespace />fm1.<portlet:namespace /><%= Constants.CMD %>.value = "<%= Constants.EXPIRE %>";
		submitForm(document.<portlet:namespace />fm1);
	}

	function <portlet:namespace />getChoice(value) {
		for (var i = 0; i < document.<portlet:namespace />fm1.<portlet:namespace />languageId.length; i++) {
			if (document.<portlet:namespace />fm1.<portlet:namespace />languageId.options[i].value == value) {
				return document.<portlet:namespace />fm1.<portlet:namespace />languageId.options[i].index;
			}
		}

		return null;
	}

	function <portlet:namespace />getSuggestionsContent() {
		var content = '';

		content += document.<portlet:namespace />fm1.<portlet:namespace/>title.value + ' ';
		content += window.<portlet:namespace />editor.getHTML();

		return content;
	}

	function <portlet:namespace />initEditor() {
		return "<%= UnicodeFormatter.toString(content) %>";
	}

	function <portlet:namespace />removeArticleLocale() {
		if (confirm("<%= UnicodeLanguageUtil.get(pageContext, "are-you-sure-you-want-to-deactivate-this-language") %>")) {
			document.<portlet:namespace />fm1.<portlet:namespace /><%= Constants.CMD %>.value = "removeArticlesLocale";
			document.<portlet:namespace />fm1.<portlet:namespace />redirect.value = "<portlet:renderURL windowState="<%= WindowState.MAXIMIZED.toString() %>"><portlet:param name="redirect" value="<%= redirect %>" /><portlet:param name="struts_action" value="/journal/edit_article" /><portlet:param name="groupId" value="<%= String.valueOf(groupId) %>" /><portlet:param name="articleId" value="<%= articleId %>" /><portlet:param name="version" value="<%= String.valueOf(version) %>" /></portlet:renderURL>&<portlet:namespace />languageId=<%= defaultLanguageId %>";
			submitForm(document.<portlet:namespace />fm1);
		}
	}

	function <portlet:namespace />selectDocumentLibrary(url) {
		document.getElementById(<portlet:namespace />documentLibraryInput).value = url;
	}

	function <portlet:namespace />selectImageGallery(url) {
		document.getElementById(<portlet:namespace />imageGalleryInput).value = url;
	}

	function <portlet:namespace />selectStructure(structureId) {
		if (document.<portlet:namespace />fm1.<portlet:namespace />structureId.value != structureId) {
			document.<portlet:namespace />fm1.<portlet:namespace />structureId.value = structureId;
			document.<portlet:namespace />fm1.<portlet:namespace />templateId.value = "";
			submitForm(document.<portlet:namespace />fm1);
		}
	}

	function <portlet:namespace />selectTemplate(structureId, templateId) {
		document.<portlet:namespace />fm1.<portlet:namespace />structureId.value = structureId;
		document.<portlet:namespace />fm1.<portlet:namespace />templateId.value = templateId;
		submitForm(document.<portlet:namespace />fm1);
	}
</script>

<form enctype="multipart/form-data" method="post" name="<portlet:namespace />fm2">
<input name="groupId" type="hidden" value="" />
<input name="articleId" type="hidden" value="" />
<input name="version" type="hidden" value="" />
<input name="title" type="hidden" value="" />
<input name="xml" type="hidden" value="" />
</form>

<form action="<portlet:actionURL windowState="<%= WindowState.MAXIMIZED.toString() %>"><portlet:param name="struts_action" value="/journal/edit_article" /></portlet:actionURL>" enctype="multipart/form-data" method="post" name="<portlet:namespace />fm1" onSubmit="<portlet:namespace />saveArticle(); return false;">
<input name="<portlet:namespace />portletResource" type="hidden" value="<%= HtmlUtil.escapeAttribute(portletResource) %>" />
<input name="<portlet:namespace /><%= Constants.CMD %>" type="hidden" value="" />
<input name="<portlet:namespace />tabs2" type="hidden" value="<%= HtmlUtil.escapeAttribute(tabs2) %>" />
<input name="<portlet:namespace />redirect" type="hidden" value="<%= HtmlUtil.escapeAttribute(redirect) %>" />
<input name="<portlet:namespace />originalRedirect" type="hidden" value="<%= HtmlUtil.escapeAttribute(originalRedirect) %>" />
<input name="<portlet:namespace />referringPortletResource" type="hidden" value="<%= HtmlUtil.escapeAttribute(referringPortletResource) %>" />
<input name="<portlet:namespace />groupId" type="hidden" value="<%= groupId %>" />
<input name="<portlet:namespace />articleId" type="hidden" value="<%= articleId %>" />
<input name="<portlet:namespace />version" type="hidden" value="<%= version %>" />
<input name="<portlet:namespace />content" type="hidden" value="" />
<input name="<portlet:namespace />articleURL" type="hidden" value="<portlet:renderURL windowState="<%= WindowState.MAXIMIZED.toString() %>"><portlet:param name="struts_action" value="/journal/edit_article" /></portlet:renderURL>" />
<input name="<portlet:namespace />approve" type="hidden" value="" />
<input name="<portlet:namespace />saveAndContinue" type="hidden" value="" />
<input name="<portlet:namespace />deleteArticleIds" type="hidden" value="<%= articleId + EditArticleAction.VERSION_SEPARATOR + version %>" />
<input name="<portlet:namespace />expireArticleIds" type="hidden" value="<%= articleId + EditArticleAction.VERSION_SEPARATOR + version %>" />
<input name="<portlet:namespace />defaultLocale" type="hidden" value="<%= HtmlUtil.escapeAttribute(defaultLanguageId) %>" id="<portlet:namespace />defaultLocale" />
<input name="<portlet:namespace />parentStructureId" type="hidden" value="<%= parentStructureId %>" id="<portlet:namespace />parentStructureId" />

<liferay-ui:tabs
	names="web-content"
	formName="fm1"
	backURL="<%= redirect %>"
/>

<table class="lfr-table" width="100%">
<tr>
	<td valign="top">
		<liferay-ui:error exception="<%= ArticleContentException.class %>" message="please-enter-valid-content" />
		<liferay-ui:error exception="<%= ArticleIdException.class %>" message="please-enter-a-valid-id" />
		<liferay-ui:error exception="<%= ArticleTitleException.class %>" message="please-enter-a-valid-name" />
		<liferay-ui:error exception="<%= DuplicateArticleIdException.class %>" message="please-enter-a-unique-id" />
		<liferay-ui:asset-tags-error />

		<table class="lfr-table" id="<portlet:namespace />articleHeaderEdit">
		<tr>
			<td>
				<liferay-ui:message key="id" />
			</td>
			<td>
				<c:choose>
					<c:when test="<%= PropsValues.JOURNAL_ARTICLE_FORCE_AUTOGENERATE_ID %>">
						<c:choose>
							<c:when test="<%= article == null %>">
								<liferay-ui:message key="autogenerate-id" />

								<input name="<portlet:namespace />newArticleId" type="hidden" value="" />
								<input name="<portlet:namespace />autoArticleId" type="hidden" value="true" />
							</c:when>
							<c:otherwise>
								<%= articleId %>
							</c:otherwise>
						</c:choose>
					</c:when>
					<c:otherwise>
						<table class="lfr-table">
						<tr>
							<td>
								<c:choose>
									<c:when test="<%= article == null %>">
										<liferay-ui:input-field model="<%= JournalArticle.class %>" bean="<%= article %>" field="articleId" fieldParam="newArticleId" defaultValue="<%= newArticleId %>" />
									</c:when>
									<c:otherwise>
										<%= articleId %>
									</c:otherwise>
								</c:choose>
							</td>
							<td>
								<c:if test="<%= article == null %>">
									<liferay-ui:input-checkbox param="autoArticleId" />

									<liferay-ui:message key="autogenerate-id" />
								</c:if>
							</td>
						</tr>
						</table>
					</c:otherwise>
				</c:choose>
			</td>
		</tr>
		<tr>
			<td>
				<liferay-ui:message key="name" />
			</td>
			<td>
				<liferay-ui:input-field model="<%= JournalArticle.class %>" bean="<%= article %>" field="title" />
			</td>
		</tr>
		<tr>
			<td>
				<liferay-ui:message key="language" />
			</td>
			<td>
				<input name="<portlet:namespace />lastLanguageId" type="hidden" value="<%= languageId %>" />

				<table class="lfr-table">
				<tr>
					<td>
						<select id="<portlet:namespace />languageIdSelect" <%= (article == null) ? "disabled" : "" %> name="<portlet:namespace />languageId">

							<%
							Locale[] locales = LanguageUtil.getAvailableLocales();

							for (int i = 0; i < locales.length; i++) {
							%>

								<option <%= (languageId.equals(LocaleUtil.toLanguageId(locales[i]))) ? "selected" : "" %> value="<%= LocaleUtil.toLanguageId(locales[i]) %>"><%= locales[i].getDisplayName(locale) %></option>

							<%
							}
							%>

						</select>

						<c:if test="<%= (article != null) && !languageId.equals(defaultLanguageId) %>">
							<input type="button" name="<portlet:namespace />removeArticleLocaleButton" value="<liferay-ui:message key="remove" />" onClick="<portlet:namespace />removeArticleLocale();" />
						</c:if>
					</td>
					<td>
						<table class="lfr-table">
						<tr>
							<td>
								<liferay-ui:message key="default-language" />
							</td>
							<td>
								<select
									<c:choose>
										<c:when test="<%= article == null %>">
											disabled
										</c:when>
										<c:otherwise>
											name="<portlet:namespace />defaultLanguageId"
										</c:otherwise>
									</c:choose>
									id="<portlet:namespace />defaultLanguageIdSelect"
									onChange="<portlet:namespace />changeLanguageView();"
								>

									<%
									if ((availableLocales != null) && (availableLocales.length > 0)) {
										boolean wasLanguageId = false;

										for (int i = 0; i < availableLocales.length; i++) {
											if (availableLocales[i].equals(languageId)) {
												wasLanguageId = true;
											}

											Locale availableLocale = LocaleUtil.fromLanguageId(availableLocales[i]);
									%>

											<option <%= (availableLocales[i].equals(defaultLanguageId)) ? "selected" : "" %> value="<%= availableLocales[i] %>"><%= availableLocale.getDisplayName(availableLocale) %></option>

									<%
										}

										if (!wasLanguageId) {
											Locale languageLocale = LocaleUtil.fromLanguageId(languageId);
									%>

											<option value="<%= languageId %>"><%= languageLocale.getDisplayName(languageLocale) %></option>

									<%
										}
									}
									else {
									%>

										<option value="<%= HtmlUtil.escapeAttribute(defaultLanguageId) %>"><%= defaultLocale.getDisplayName(defaultLocale) %></option>

									<%
									}
									%>

								</select>

								<c:if test="<%= article == null %>">
									<input name="<portlet:namespace />defaultLanguageId" type="hidden" value="<%= HtmlUtil.escapeAttribute(defaultLanguageId) %>" />
								</c:if>
							</td>
						</tr>
						</table>
					</td>
				</tr>
				</table>
			</td>
		</tr>
		</table>

		<br />

		<div id="<portlet:namespace />journalArticleContainer" class="journal-article-container">
			<c:choose>
				<c:when test="<%= structure == null %>">
				<div id="<portlet:namespace />structureTreeWrapper">

					<ul id="<portlet:namespace />structureTree" class="structure-tree">
						<li class="structure-field" data-component-type="text" data-component-name="TextField">
							<span class='journal-article-close'></span>
							<span class='folder'>
								<div class="field-container">
									<div class="journal-article-move-handler"></div>
									<label for="" class="journal-article-field-label"><span>TextField</span></label>
									<div class="journal-article-component-container">
										<input class="principal-field-element" type="text" value="" size="75" />
									</div>

									<div class="journal-article-required-message portlet-msg-error"><liferay-ui:message key="this-field-is-required" /></div>

									<div class="journal-article-buttons">
										<input type="button" class="edit-button" value="<liferay-ui:message key="edit-options" />" />
										<input type="button" class="repeatable-button" value="<liferay-ui:message key="repeat" />" />
									</div>
								</div>
								<ul class='folder-droppable'></ul>
							</span>
						</li>
						<li class="structure-field" data-component-type="text_area" data-component-name="TextAreaField">
							<span class='journal-article-close'></span>
							<span class='folder'>
								<div class="field-container">
									<div class="journal-article-move-handler"></div>
									<label for="" class="journal-article-field-label"><span>TextAreaField</span></label>
									<div class="journal-article-component-container">
										<liferay-ui:input-editor name='<%= renderResponse.getNamespace() + "structure_el_TextAreaField_content" %>' editorImpl="<%= EDITOR_WYSIWYG_IMPL_KEY %>" toolbarSet="liferay-article" onChangeMethod='<%= renderResponse.getNamespace() + "editorContentChanged" %>' width="100%" />
									</div>

									<div class="journal-article-required-message portlet-msg-error"><liferay-ui:message key="this-field-is-required" /></div>

									<div class="journal-article-buttons">
										<input type="button" class="edit-button" value="<liferay-ui:message key="edit-options" />" />
										<input type="button" class="repeatable-button" value="<liferay-ui:message key="repeat" />" />
									</div>
								</div>
								<ul class='folder-droppable'></ul>
							</span>
						</li>
					</ul>

				</div>
				</c:when>
				<c:otherwise>

				<%
				Document xsdDoc = SAXReaderUtil.read(structure.getMergedXsd());


					if (contentDoc != null) {
					%>

						<input name="<portlet:namespace />available_locales" type="hidden" value="<%= HtmlUtil.escapeAttribute(defaultLanguageId) %>" />

					<%
						boolean languageFound = false;

						if ((availableLocales != null) && (availableLocales.length > 0)) {
							for (int i = 0; i < availableLocales.length ; i++) {
								if (!availableLocales[i].equals(defaultLanguageId)) {
					%>

									<input name="<portlet:namespace />available_locales" type="hidden" value="<%= availableLocales[i] %>" />

									<script type="text/javascript">
										document.<portlet:namespace />fm1.<portlet:namespace />languageId.options[<portlet:namespace />getChoice('<%= availableLocales[i] %>')].className = 'focused';
									</script>

					<%
								}
								else{
								%>

									<script type="text/javascript">
										document.<portlet:namespace />fm1.<portlet:namespace />languageId.options[<portlet:namespace />getChoice('<%= availableLocales[i] %>')].className = 'focused';
									</script>

					<%
								}

								if (availableLocales[i].equals(languageId)) {
									languageFound = true;
								}
							}
						}

						if (!languageFound && !languageId.equals(defaultLanguageId)) {
					%>

							<input name="<portlet:namespace />available_locales" type="hidden" value="<%= languageId %>" />

							<script type="text/javascript">
								document.<portlet:namespace />fm1.<portlet:namespace />removeArticleLocaleButton.disabled = true;
							</script>

					<%
						}
					}

				else {
					contentDoc = SAXReaderUtil.createDocument(SAXReaderUtil.createElement("root"));
				%>

						<input name="<portlet:namespace />available_locales" type="hidden" value="<%= HtmlUtil.escapeAttribute(defaultLanguageId) %>" />

				<%
				}
				%>
					<div id="<portlet:namespace />structureTreeWrapper" class="structure-tree-wrapper">
						<ul id="<portlet:namespace />structureTree" class="structure-tree">
							<% _format(groupId, contentDoc.getRootElement(), xsdDoc.getRootElement(), new IntegerWrapper(0), new Integer(-1), pageContext, request); %>
						</ul>
					</div>
				</c:otherwise>
			</c:choose>

			<c:if test="<%= article == null %>">
				<table class="lfr-table">
				<tr>
					<td colspan="2">
						<br />
					</td>
				</tr>
				<tr>
					<td>
						<liferay-ui:message key="permissions" />
					</td>
					<td>
						<liferay-ui:input-permissions
							modelName="<%= JournalArticle.class.getName() %>"
						/>
					</td>
				</tr>
				</table>
			</c:if>
		</div>

		<br />

		<%
		String abstractId = portletDisplay.getNamespace() + "abstract";
		String abstractTitle = LanguageUtil.get(pageContext, "abstract");
		%>

		<liferay-ui:panel id="<%= abstractId %>" title="<%= abstractTitle %>" defaultState="closed" persistState="<%= true %>" extended="<%= false %>">
			<liferay-ui:error exception="<%= ArticleSmallImageNameException.class %>">

			<%
			String[] imageExtensions = PrefsPropsUtil.getStringArray(PropsKeys.JOURNAL_IMAGE_EXTENSIONS, StringPool.COMMA);
			%>

			<liferay-ui:message key="image-names-must-end-with-one-of-the-following-extensions" /> <%= StringUtil.merge(imageExtensions, ", ") %>.
			</liferay-ui:error>

			<liferay-ui:error exception="<%= ArticleSmallImageSizeException.class %>" message="please-enter-a-small-image-with-a-valid-file-size" />

			<table class="lfr-table">
			<tr>
				<td>
					<liferay-ui:message key="description" />
				</td>
				<td>
					<liferay-ui:input-field model="<%= JournalArticle.class %>" bean="<%= article %>" field="description" />
				</td>
			</tr>
			<tr>
				<td colspan="2">
					<br />
				</td>
			</tr>
			<tr>
				<td>
					<liferay-ui:message key="small-image-url" />
				</td>
				<td>
					<liferay-ui:input-field model="<%= JournalArticle.class %>" bean="<%= article %>" field="smallImageURL" />
				</td>
			</tr>
			<tr>
				<td>
					<span style="font-size: xx-small;">-- <%= LanguageUtil.get(pageContext, "or").toUpperCase() %> --</span> <liferay-ui:message key="small-image" />
				</td>
				<td>
					<input class="lfr-input-text" name="<portlet:namespace />smallFile" type="file" />
				</td>
			</tr>
			<tr>
				<td>
					<liferay-ui:message key="use-small-image" />
				</td>
				<td>
					<liferay-ui:input-field model="<%= JournalArticle.class %>" bean="<%= article %>" field="smallImage" />
				</td>
			</tr>

			<liferay-ui:custom-attributes-available className="<%= JournalArticle.class.getName() %>">
				<tr>
					<td colspan="2">
						<br />
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<liferay-ui:custom-attribute-list
							className="<%= JournalArticle.class.getName() %>"
							classPK="<%= (article != null) ? article.getResourcePrimKey() : 0 %>"
							editable="<%= true %>"
							label="<%= true %>"
						/>
					</td>
				</tr>
			</liferay-ui:custom-attributes-available>

			</table>
		</liferay-ui:panel>

		<br />

		<div>
			<%
			boolean hasSavePermission = false;

			if (article != null) {
				hasSavePermission = JournalArticlePermission.contains(permissionChecker, groupId, articleId, ActionKeys.UPDATE);
			}
			else {
				hasSavePermission = JournalPermission.contains(permissionChecker, scopeGroupId, ActionKeys.ADD_ARTICLE);
			}
			%>

			<c:if test="<%= hasSavePermission %>">
				<input id="<portlet:namespace />saveArticleBtn" type="button" value="<liferay-ui:message key="save" />" />

				<input id="<portlet:namespace />saveArticleAndContinueBtn" name="save-and-continue" type="button" value="<liferay-ui:message key="save-and-continue" />" />

				<c:if test="<%= ((article == null) || ((article != null) && !article.isApproved())) && JournalPermission.contains(permissionChecker, scopeGroupId, ActionKeys.APPROVE_ARTICLE) %>">
					<input id="<portlet:namespace />saveArticleAndApproveBtn"  type="button" value="<liferay-ui:message key="save-and-approve" />" />
				</c:if>
			</c:if>

			<c:if test="<%= Validator.isNotNull(structureId) %>">
				<input id="<portlet:namespace />previewArticleBtn" type="button" value="<liferay-ui:message key="preview" />" />
			</c:if>

			<c:if test="<%= structure != null %>">
				<input id="<portlet:namespace />downloadArticleContentBtn" type="button" value="<liferay-ui:message key="download" />" />
			</c:if>

			<input type="button" value="<liferay-ui:message key="cancel" />" onClick="location.href = '<%= HtmlUtil.escapeAttribute(redirect) %>';" />
		</div>
	</td>

	<td valign="top">
		<%@ include file="edit_article_extra.jspf" %>
	</td>
</tr>
</table>

</form>

<%@ include file="edit_article_structure_extra.jspf" %>

<c:if test="<%= windowState.equals(WindowState.MAXIMIZED) %>">
	<script type="text/javascript">
		<c:choose>
			<c:when test="<%= PropsValues.JOURNAL_ARTICLE_FORCE_AUTOGENERATE_ID %>">
				Liferay.Util.focusFormField(document.<portlet:namespace />fm1.<portlet:namespace />title);
			</c:when>
			<c:otherwise>
				Liferay.Util.focusFormField(document.<portlet:namespace />fm1.<portlet:namespace /><%= (article == null) ? "newArticleId" : "title" %>);
			</c:otherwise>
		</c:choose>
	</script>
</c:if>

<script>
	jQuery(
		function() {
			Liferay.Portlet.Journal.PROXY = {};
			Liferay.Portlet.Journal.PROXY.doAsUserId = '<%= HttpUtil.encodeURL(doAsUserId) %>';
			Liferay.Portlet.Journal.PROXY.editorImpl = '<%= editorImpl %>';
			Liferay.Portlet.Journal.PROXY.pathThemeCss = '<%= HttpUtil.encodeURL(themeDisplay.getPathThemeCss()) %>';
			Liferay.Portlet.Journal.PROXY.portletNamespace = '<portlet:namespace />';

			new Liferay.Portlet.Journal(Liferay.Portlet.Journal.PROXY.portletNamespace, '<%= articleId %>', '<%= instanceIdKey %>');
		}
	);
</script>

<%!
public static final String EDITOR_WYSIWYG_IMPL_KEY = "editor.wysiwyg.portal-web.docroot.html.portlet.journal.edit_article_content.jsp";

private void _format(long groupId, Element contentParentElement, Element xsdParentElement, IntegerWrapper count, Integer depth, PageContext pageContext, HttpServletRequest request) throws Exception {
	depth = new Integer(depth.intValue() + 1);

	String languageId = LanguageUtil.getLanguageId(request);

	List<Element> xsdElements = xsdParentElement.elements();

	for (Element xsdElement : xsdElements) {

		String nodeName = xsdElement.getName();

		String elName = xsdElement.attributeValue("name", StringPool.BLANK);

		String elType = xsdElement.attributeValue("type", StringPool.BLANK);

		String repeatable = xsdElement.attributeValue("repeatable");

		boolean elRepeatable = GetterUtil.getBoolean(repeatable);

		String elParentStructureId = xsdElement.attributeValue("parent-structure-id");

		if (nodeName.equals("meta-data") || nodeName.equals("entry")) {
			continue;
		}

		HashMap<String, String> metaDataEl = _getMetaData(xsdElement, elName);

		List<Element> elSiblings = null;

		List<Element> contentElements = contentParentElement.elements();

		for (Element contentElement : contentElements) {
			if (elName.equals(contentElement.attributeValue("name", StringPool.BLANK))) {
				elSiblings = _getSiblings(contentParentElement, elName);

				break;
			}
		}

		if (elSiblings == null) {
			elSiblings = new ArrayList<Element>();

			Element contentElement = SAXReaderUtil.createElement("dynamic-element");

			contentElement.addAttribute("instance-id", PwdGenerator.getPassword());
			contentElement.addAttribute("name", elName);
			contentElement.addAttribute("type", elType);

			contentElement.add(SAXReaderUtil.createElement("dynamic-content"));

			elSiblings.add(contentElement);
		}

		for (int i = 0; i < elSiblings.size(); i++) {
			Element contentElement = elSiblings.get(i);

			String elInstanceId = contentElement.attributeValue("instance-id");

			String elContent = GetterUtil.getString(contentElement.elementText("dynamic-content"));

			if (!elType.equals("text_area")) {
				elContent = HtmlUtil.toInputSafe(elContent);
			}

			String elLanguageId = StringPool.BLANK;

			Element dynamicContentEl = contentElement.element("dynamic-content");

			if (dynamicContentEl != null) {
				elLanguageId = dynamicContentEl.attributeValue("language-id", StringPool.BLANK);
			}
			else {
				elLanguageId = languageId;
			}

			request.setAttribute(WebKeys.JOURNAL_ARTICLE_GROUP_ID, String.valueOf(groupId));

			request.setAttribute(WebKeys.JOURNAL_ARTICLE_CONTENT_EL, contentElement);
			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_EL, xsdElement);
			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_EL_CONTENT, elContent);
			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_EL_COUNT, count);
			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_EL_DEPTH, depth);
			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_EL_INSTANCE_ID, elInstanceId);
			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_EL_LANGUAGE_ID, elLanguageId);
			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_EL_META_DATA, metaDataEl);
			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_EL_NAME, elName);
			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_EL_PARENT_ID, elParentStructureId);
			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_EL_REPEATABLE, String.valueOf(elRepeatable));
			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_EL_REPEATABLE_PROTOTYPE, (i == 0) ? "1" : "0");
			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_EL_TYPE, elType);

			pageContext.include("/html/portlet/journal/edit_article_content_xsd_el.jsp");

			count.increment();

			if (!elType.equals("list") && !elType.equals("multi-list") && (contentElement.elements().size() > 0)) {

				pageContext.include("/html/portlet/journal/edit_article_content_xsd_el_top.jsp");

				_format(groupId, contentElement, xsdElement, count, depth, pageContext, request);

				request.setAttribute(WebKeys.JOURNAL_STRUCTURE_CLOSE_DROPPABLE_TAG, "true");

				pageContext.include("/html/portlet/journal/edit_article_content_xsd_el_bottom.jsp");
			}

			request.setAttribute(WebKeys.JOURNAL_STRUCTURE_CLOSE_DROPPABLE_TAG, "false");

			pageContext.include("/html/portlet/journal/edit_article_content_xsd_el_bottom.jsp");
		}
	}
}

private List<Element> _getSiblings(Element element, String name) {
	List<Element> elements = new ArrayList<Element>();

	Iterator<Element> itr = element.elements().iterator();

	while (itr.hasNext()) {
		Element curElement = itr.next();

		if (name.equals(curElement.attributeValue("name", StringPool.BLANK))) {
			elements.add(curElement);
		}
	}

	return elements;
}

private HashMap<String, String> _getMetaData(Element xsdElement, String elName) {
	HashMap<String, String> metaDataEl = new HashMap<String, String>();

	Element metaData = xsdElement.element("meta-data");

	if (Validator.isNotNull(metaData)) {
		List<Element> metaDataElements = metaData.elements();

		for (Element metaDataElement : metaDataElements) {
			String name = metaDataElement.attributeValue("name");
			String content = metaDataElement.getText().trim();

			metaDataEl.put(name, content);
		}
	}
	else {
		metaDataEl.put("label", elName);
	}

	return metaDataEl;
}
%>