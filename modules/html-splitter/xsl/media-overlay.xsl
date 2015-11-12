<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:html="http://www.w3.org/1999/xhtml"
	xmlns:smil="http://www.w3.org/ns/SMIL"
	version="2.0"
	exclude-result-prefixes="xs">
	
	<!-- SMIL PROCESSING: if a raw SMIL file is present, relate its chunks’ text links to the HTML file they point to. -->
	
	<xsl:template name="smil">
		<xsl:param name="smil" as="element(smil:smil)"/>
		<xsl:param name="text" as="document-node(element(html:chunks))"/>
		
		<xsl:variable name="audio-anchors" select="$text//*[@class eq 'au']" as="element(*)*"/>
		
		<xsl:variable name="html-anchored-groups" as="element(smil:audio-anchored-group)*">
			<xsl:for-each-group select="$audio-anchors" group-starting-with="*[starts-with(@id, 'au-')]">
				<audio-anchored-group xmlns="http://www.w3.org/ns/SMIL" count="{count(current-group())}"
					has-id="{exists(@id[starts-with(., 'au-')])}">
					<xsl:sequence select="current-group()"/>
				</audio-anchored-group>
			</xsl:for-each-group>
		</xsl:variable>
		
		<xsl:variable name="smil-anchored-groups" as="element(smil:audio-anchored-group)*">
			<xsl:for-each-group select="$smil/smil:body/smil:par" group-starting-with="smil:par[smil:text[matches(@src, '\S')]]">
				<audio-anchored-group xmlns="http://www.w3.org/ns/SMIL" count="{count(current-group())}"
					has-id="{exists(smil:text[matches(@src, '\S')])}">
					<xsl:sequence select="current-group()"/>
				</audio-anchored-group>
			</xsl:for-each-group>
		</xsl:variable>
		
		<xsl:variable name="patched-smil-pars" as="element(smil:par)*">
			<xsl:choose>
				<xsl:when test="count($html-anchored-groups) eq count($smil-anchored-groups)">
					<xsl:for-each select="$html-anchored-groups">
						<xsl:variable name="group-number" select="position()" as="xs:integer"/>
						<xsl:variable name="raw-smil-items" select="$smil-anchored-groups[position() eq $group-number]/*"
							as="element(smil:par)+"/>
						<xsl:choose>
							<xsl:when test="count(*) eq count($raw-smil-items)">
								<xsl:variable name="idref-to-html"
									select="replace(string-join(($raw-smil-items[1]/smil:text/@src, ''), ''), '^.*#', '')" as="xs:string"/>
								<xsl:choose>
									<xsl:when
										test="string-length($idref-to-html) gt 0
										and not(*[1]/@id = $idref-to-html)
										and $html-anchored-groups/*/@id = $idref-to-html">
										<xsl:message terminate="yes">Misalignment? Some other html anchor group than group #<xsl:value-of
											select="$group-number"/> (namely, #<xsl:value-of
												select="$html-anchored-groups[*/@id = $idref-to-html]/position()"/>) matches the SMIL file's idref
											<xsl:value-of select="$idref-to-html"/>
										</xsl:message>
									</xsl:when>
									<xsl:otherwise>
										<xsl:for-each select="*">
											<xsl:variable name="item-number" select="position()" as="xs:integer"/>
											<xsl:apply-templates select="$raw-smil-items[position() = $item-number]" mode="link-smil">
												<xsl:with-param name="corresponding-text" select="." as="element(*)" tunnel="yes"/>
											</xsl:apply-templates>
										</xsl:for-each>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:otherwise>
								<xsl:message terminate="yes">Item counts in group <xsl:value-of select="$group-number"/> (starting with
									<xsl:value-of select="*[1]/@id"/>) differ. Text: <xsl:value-of select="count(*)"/>, SMIL: <xsl:value-of
										select="count($raw-smil-items)"/>. First text item: <xsl:copy-of select="*[1]"/>, first SMIL item:
									<xsl:copy-of select="$raw-smil-items[1]"/>
								</xsl:message>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:message terminate="yes">Group counts differ. Text: <xsl:value-of select="count($html-anchored-groups)"/>, SMIL:
						<xsl:value-of select="count($smil-anchored-groups)"/>. </xsl:message>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:for-each-group select="$patched-smil-pars" group-by="replace(smil:text/@src, '[^.]+$', '')">
			<xsl:result-document href="{$datadir}/{current-grouping-key()}smil" format="xml">
				<smil xmlns="http://www.w3.org/ns/SMIL">
					<body xmlns="http://www.w3.org/ns/SMIL">
						<xsl:sequence select="current-group()"/>
					</body>
				</smil>
			</xsl:result-document>
		</xsl:for-each-group>
		
	</xsl:template>
	
	<xsl:template match="smil:text" mode="link-smil">
		<xsl:param name="corresponding-text" as="element(*)" tunnel="yes"/>
		<xsl:copy copy-namespaces="no">
			<xsl:attribute name="src"
				select="concat(
				replace(
				key('by-id', $corresponding-text/@id, $chunks)/ancestor::html:chunk/@file, '^.*?([^/]+)$', '$1'),
				'#', $corresponding-text/@id
				)"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="smil:par/@id" mode="link-smil">
		<xsl:param name="corresponding-text" as="element(*)" tunnel="yes"/>
		<xsl:attribute name="id" select="$corresponding-text/@id"/>
	</xsl:template>
	
</xsl:stylesheet>