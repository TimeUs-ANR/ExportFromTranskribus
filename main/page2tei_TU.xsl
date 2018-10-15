<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:p="http://schema.primaresearch.org/PAGE/gts/pagecontent/2013-07-15"
    xmlns:mets="http://www.loc.gov/METS/" xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:local="local"
    xmlns:xstring="https://github.com/dariok/XStringUtils" exclude-result-prefixes="#all"
    xmlns:tu="timeUs" 
    xmlns:temp="temporary" version="2.0">

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Author:</xd:b> Alix Chagué, alix.chague@inria.fr</xd:p>
            <xd:p>This stylesheet, when applied to PAGE format xml files, create a valid TEI file,
                matching Time Us' needs
                (http://timeusage.paris.inria.fr/mediawiki/index.php/Accueil)</xd:p>
            <xd:p>It is adapted, in july 2018, from Dario Kampkaspar's <xd:b>page2tei</xd:b> project
                for Transkribus: https://github.com/dariok/page2tei</xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:output method="xml" indent="yes"/>

    <!-- use extended string functions from https://github.com/dariok/XStringUtils -->
    <xsl:include href="string-pack.xsl"/>

    <xsl:param name="debug" select="false()"/>

    <xd:doc>
        <xd:desc>Entry point: start at the top of the xml file (PcGts element)</xd:desc>
    </xd:doc>
    <xsl:template match="/p:PcGts">
        <TEI>
            <teiHeader>
                <fileDesc>
                    <titleStmt>
                        <title><xsl:value-of select="p:Metadata/temp:title"/><xsl:choose>
                            <xsl:when test="p:Page">, page <xsl:value-of select="p:Metadata/temp:pagenumber"/></xsl:when>
                        </xsl:choose> - Transcription</title>
                        <!-- custom -->
                        <editor>Manuela Martini</editor>
                        <!-- end custom -->
                        <respStmt><name><xsl:value-of select="p:Metadata/temp:uploader"/></name>, <resp>créateur⋅rice du document Transkribus (TRP).</resp></respStmt>
                    </titleStmt>
                    <publicationStmt>
                        <!-- custom -->
                        <bibl><publisher>Time Us</publisher> (<date>2017-2020</date>) : http://timeusage.paris.inria.fr/mediawiki/index.php/Accueil</bibl>
                        <!-- end custom -->
                    </publicationStmt>
                    <sourceDesc>
                        <p><xsl:value-of select="p:Metadata/temp:desc"/></p>
                    </sourceDesc>
                </fileDesc>
                <encodingDesc>
                    <!-- custom -->
                    <projectDesc>TIME US est un projet ANR dont le but est de reconstituer les rémunérations et les budgets temps des travailleur⋅ses du textile dans quatre villes industrielles française (Lille, Paris, Lyon, Marseille) dans une perspective européenne et de longue durée. Il réunit une équipe pluridisciplinaire d'historiens des techniques, de l'économie et du travail, des spécialistes du traitement automatique des langues et des sociologues spécialistes des budgets familiaux. Il vise à donner des clés pour comprendre le gender gap en analysant les mutations du travail et la répartition du temps et des tâches au sein des ménages pendant la première industrialisation. Pour ce faire, le projet met en place une action de transcription et d'annotation de documents d'archives datés de la fin du XVIIe au début du XXe siècle.</projectDesc>
                    <editorialDecl>
                        <p>Les transcriptions et leur annotations sont réalisées à l'aide de la plate-forme Transkribus.</p>
                        <p>Statut de la transcription lors de son export : "<xsl:value-of select="p:Metadata/temp:tsStatus"/>".</p>
                    </editorialDecl>
                    <!-- end custom -->
                </encodingDesc>
                <xsl:if test="count(p:Metadata/temp:language) &gt; 0">
                    <profileDesc>
                        <langUsage>
                            <xsl:for-each select="p:Metadata/temp:language">
                                <language><xsl:value-of select="."/></language>
                            </xsl:for-each>
                        </langUsage>
                    </profileDesc>
                </xsl:if>                
                <revisionDesc>
                    <change type="Created"><xsl:value-of select="p:Metadata/p:Created"/></change>
                    <change type="LastChange"><xsl:value-of select="p:Metadata/p:LastChange"/></change>
                    <change type="ToTEI"><xsl:value-of select="current-dateTime()"/></change>
                </revisionDesc>
            </teiHeader>
            <xsl:if test="not($debug)">
                <xsl:apply-templates select="p:Page" mode="facsimile"/>
            </xsl:if>
            <text>
                <body>
                    <xsl:apply-templates select="p:Page" mode="text"></xsl:apply-templates>
                </body>
            </text>
        </TEI>
    </xsl:template>

    <xd:doc>
        <xd:p>Create tei:surface and tei:graphic</xd:p>
    </xd:doc>
    <xsl:template match="p:Page" mode="facsimile">
        <xsl:variable name="url" select="@temp:urltoimg"/>
        <xsl:variable name="numCurr" select="@temp:id"/>
        <xsl:variable name="imageName" select="@imageFilename"/>
        <xsl:variable name="type" select="substring-after(@imageFilename, '.')"/>

        <facsimile xml:id="facs_{$numCurr}">
            <surface ulx="0" uly="0" lrx="{@imageWidth}" lry="{@imageHeight}">
                <graphic url="{$url}" width="{@imageWidth}px" height="{@imageHeight}px"/>
                <xsl:apply-templates
                    select="p:PrintSpace | p:TextRegion | p:SeparatorRegion | p:GraphicRegion"
                    mode="facsimile">
                    <xsl:with-param name="numCurr" select="$numCurr" tunnel="true"/>
                </xsl:apply-templates>
            </surface>
        </facsimile>
    </xsl:template>

    <xd:doc>
        <xd:desc>Create zones (tei:zone) within facsimile/surface</xd:desc>
        <xd:param name="numCurr">Numerus currens of the current page</xd:param>
    </xd:doc>
    <xsl:template
        match="p:PrintSpace | p:TextRegion | p:SeparatorRegion | p:GraphicRegion | p:TextLine"
        mode="facsimile">
        <xsl:param name="numCurr" tunnel="true"/>

        <xsl:variable name="renditionValue">
            <xsl:choose>
                <xsl:when test="local-name() = 'TextRegion'">TextRegion</xsl:when>
                <xsl:when test="local-name() = 'SeparatorRegion'">Separator</xsl:when>
                <xsl:when test="local-name() = 'GraphicRegion'">Graphic</xsl:when>
                <xsl:when test="local-name() = 'TextLine'">Line</xsl:when>
                <xsl:otherwise>printspace</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="custom" as="map(xs:string, xs:string)">
            <xsl:map>
                <xsl:for-each-group select="tokenize(@custom || ' lfd {' || $numCurr, '} ')"
                    group-by="substring-before(., ' ')">
                    <xsl:map-entry key="substring-before(., ' ')"
                        select="string-join(substring-after(., '{'), '–')"/>
                </xsl:for-each-group>
            </xsl:map>
        </xsl:variable>

        <xsl:if test="$renditionValue = 'Line'">
            <xsl:text> 
            </xsl:text>
        </xsl:if>
        <zone points="{p:Coords/@points}" rendition="{$renditionValue}">
            <xsl:if test="$renditionValue != 'printspace'">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="concat('facs_', $numCurr, '_', @id)"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="@type">
                <xsl:attribute name="subtype">
                    <xsl:value-of select="@type"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="map:contains($custom, 'structure') and not(@type)">
                <xsl:attribute name="subtype"
                    select="substring-after(substring-before(map:get($custom, 'structure'), ';'), ':')"
                />
            </xsl:if>
            <xsl:apply-templates select="p:TextLine" mode="facsimile"/>
            <xsl:if test="not($renditionValue = ('Line', 'Graphic', 'Separator', 'printspace'))">
                <xsl:text>     
                </xsl:text>
            </xsl:if>

        </zone>
    </xsl:template>

    <xd:doc>
        <xd:desc>create the page content</xd:desc>
        <xd:param name="numCurr">Numerus currens of the current page</xd:param>
    </xd:doc>
    <!-- Templates for PAGE, text -->
    <xsl:template match="p:Page" mode="text">
        <xsl:variable name="numCurr" select="@tu:id"/>

        <pb facs="#facs_{$numCurr}" n="{$numCurr}"/>
        <xsl:apply-templates select="p:TextRegion | p:SeparatorRegion | p:GraphicRegion" mode="text">
            <xsl:with-param name="numCurr" select="$numCurr" tunnel="true"/>
        </xsl:apply-templates>
    </xsl:template>

    <xd:doc>
        <xd:desc>create p per TextRegion</xd:desc>
        <xd:param name="numCurr"/>
    </xd:doc>
    <xsl:template match="p:TextRegion" mode="text">
        <xsl:param name="numCurr" tunnel="true"/>
        <p facs="#facs_{$numCurr}_{@id}">
            <xsl:apply-templates select="p:TextLine"/>
        </p>
    </xsl:template>

    <xd:doc>
        <xd:desc>Converts one line of PAGE to one line of TEI</xd:desc>
        <xd:param name="numCurr">Numerus currens, to be tunneled through from the page
            level</xd:param>
    </xd:doc>
    <xsl:template match="p:TextLine">
        <xsl:param name="numCurr" tunnel="true"/>

        <xsl:variable name="text" select="p:TextEquiv/p:Unicode"/>
        <xsl:variable name="custom" as="text()*">
            <xsl:for-each select="tokenize(@custom, '}')">
                <xsl:choose>
                    <xsl:when
                        test="string-length() &lt; 1 or starts-with(., 'readingOrder') or starts-with(normalize-space(), 'structure')"/>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="starts" as="map(*)">
            <xsl:map>
                <xsl:if test="count($custom) &gt; 0">
                    <xsl:for-each-group select="$custom"
                        group-by="substring-before(substring-after(., 'offset:'), ';')">
                        <xsl:map-entry key="xs:int(current-grouping-key())" select="current-group()"
                        />
                    </xsl:for-each-group>
                </xsl:if>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="ends" as="map(*)">
            <xsl:map>
                <xsl:if test="count($custom) &gt; 0">
                    <xsl:for-each-group select="$custom"
                        group-by="
                            xs:int(substring-before(substring-after(., 'offset:'), ';'))
                            + xs:int(substring-before(substring-after(., 'length:'), ';'))">
                        <xsl:map-entry key="current-grouping-key()" select="current-group()"/>
                    </xsl:for-each-group>
                </xsl:if>
            </xsl:map>
        </xsl:variable>
        <xsl:variable name="prepped">
            <xsl:for-each select="0 to string-length($text)">
                <xsl:if test=". &gt; 0">
                    <xsl:value-of select="substring($text, ., 1)"/>
                </xsl:if>
                <xsl:for-each select="map:get($starts, .)">
                    <!--<xsl:sort select="substring-before(substring-after(.,'offset:'), ';')" order="ascending"/>-->
                    <!-- end of current tag -->
                    <xsl:sort
                        select="
                            xs:int(substring-before(substring-after(., 'offset:'), ';'))
                            + xs:int(substring-before(substring-after(., 'length:'), ';'))"
                        order="descending"/>
                    <xsl:sort select="substring(., 1, 3)" order="ascending"/>
                    <xsl:element name="local:m">
                        <xsl:attribute name="type"
                            select="normalize-space(substring-before(., ' '))"/>
                        <xsl:attribute name="o" select="substring-after(., 'offset:')"/>
                        <xsl:attribute name="pos">s</xsl:attribute>
                    </xsl:element>
                </xsl:for-each>
                <xsl:for-each select="map:get($ends, .)">
                    <xsl:sort select="substring-before(substring-after(., 'offset:'), ';')"
                        order="descending"/>
                    <xsl:sort select="substring(., 1, 3)" order="descending"/>
                    <xsl:element name="local:m">
                        <xsl:attribute name="type"
                            select="normalize-space(substring-before(., ' '))"/>
                        <xsl:attribute name="o" select="substring-after(., 'offset:')"/>
                        <xsl:attribute name="pos">e</xsl:attribute>
                    </xsl:element>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="prepared">
            <xsl:for-each select="$prepped/node()">
                <xsl:choose>
                    <xsl:when test="@pos = 'e'">
                        <xsl:variable name="position" select="count(preceding-sibling::node())"/>
                        <xsl:variable name="o" select="@o"/>
                        <xsl:variable name="precs"
                            select="preceding-sibling::local:m[@pos = 's' and preceding-sibling::local:m[@o = $o]]"/>

                        <xsl:for-each select="$precs">
                            <xsl:variable name="so" select="@o"/>
                            <xsl:if
                                test="
                                    following-sibling::local:m[@pos = 'e' and @o = $so
                                    and count(preceding-sibling::node()) &gt; $position]">
                                <local:m type="{@type}" pos="e" o="{@o}"/>
                            </xsl:if>
                        </xsl:for-each>
                        <xsl:sequence select="."/>
                        <xsl:for-each select="$precs">
                            <xsl:variable name="so" select="@o"/>
                            <xsl:if
                                test="
                                    following-sibling::local:m[@pos = 'e' and @o = $so
                                    and count(preceding-sibling::node()) &gt; $position]">
                                <local:m type="{@type}" pos="s" o="{@o}"/>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="pos"
            select="xs:integer(substring-before(substring-after(@custom, 'index:'), ';')) + 1"/>

        <xsl:text>
                    </xsl:text>
        <lb facs="#facs_{$numCurr}_{@id}" n="N{format-number($pos, '000')}"/>
        <xsl:apply-templates select="$prepared/text()[not(preceding-sibling::local:m)]"/>
        <xsl:apply-templates
            select="
                $prepared/local:m[@pos = 's']
                [count(preceding-sibling::local:m[@pos = 's']) = count(preceding-sibling::local:m[@pos = 'e'])]"
        />
    </xsl:template>

    <xd:doc>
        <xd:desc>Starting milestones for (possibly nested) elements</xd:desc>
    </xd:doc>
    <xsl:template match="local:m[@pos = 's']">
        <xsl:variable name="o" select="@o"/>
        <xsl:variable name="custom" as="map(*)">
            <xsl:map>
                <xsl:variable name="t" select="tokenize(@o, ';')"/>
                <xsl:if test="count($t) &gt; 1">
                    <xsl:for-each select="$t[. != '']">
                        <xsl:map-entry key="normalize-space(substring-before(., ':'))"
                            select="normalize-space(substring-after(., ':'))"/>
                    </xsl:for-each>
                </xsl:if>
            </xsl:map>
        </xsl:variable>

        <xsl:variable name="elem">
            <local:t>
                <xsl:sequence
                    select="
                        following-sibling::node()
                        intersect following-sibling::local:m[@o = $o]/preceding-sibling::node()"
                />
            </local:t>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="@type = 'textStyle'">
                <hi
                    rend="{xstring:substring-before-if-ends(substring-after(substring-after(@o, 'length'), ';'), '}')}">
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </hi>
            </xsl:when>
            <xsl:when test="@type = 'supplied'">
                <supplied reason="">
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </supplied>
            </xsl:when>
            <xsl:when test="@type = 'abbrev'">
                <choice>
                    <expan>
                        <xsl:value-of
                            select="replace(map:get($custom, 'expansion'), '\\u0020', ' ')"/>
                    </expan>
                    <abbr>
                        <xsl:call-template name="elem">
                            <xsl:with-param name="elem" select="$elem"/>
                        </xsl:call-template>
                    </abbr>
                </choice>
            </xsl:when>
            <xsl:when test="@type = 'date'">
                <date>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </date>
            </xsl:when>
            <xsl:when test="@type = 'person'">
                <persName>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </persName>
            </xsl:when>
            <xsl:when test="@type = 'place'">
                <placeName>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </placeName>
            </xsl:when>
            <xsl:when test="@type = 'organization'">
                <orgName>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </orgName>
            </xsl:when>

            <!-- CUSTOM TAGS -->
            <xsl:when test="@type = 'TU_remuneration'">
                <rs>
                    <xsl:attribute name="type">revenue</xsl:attribute>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </rs>
            </xsl:when>
            <xsl:when test="@type = 'TU_incertitude'">
                <certainty>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:attribute name="cert">low</xsl:attribute>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </certainty>
            </xsl:when>
            <xsl:when test="@type = 'TU_adresse'">
                <address>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </address>
            </xsl:when>
            <xsl:when test="@type = 'TU_document'">
                <bibl>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </bibl>
            </xsl:when>
            <xsl:when test="@type = 'TU_personne'">
                <persName>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </persName>
            </xsl:when>
            <xsl:when test="@type = 'TU_heure'">
                <time>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </time>
            </xsl:when>
            <xsl:when test="@type = 'TU_montant'">
                <measure>
                    <xsl:attribute name="type">sum</xsl:attribute>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </measure>
            </xsl:when>
            <xsl:when test="@type = 'TU_quantite'">
                <measure>
                    <xsl:attribute name="type">count</xsl:attribute>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </measure>
            </xsl:when>
            <xsl:when test="@type = 'TU_occupation'">
                <rs>
                    <xsl:attribute name="type">occupation</xsl:attribute>
                    <choice>
                        <xsl:call-template name="attr">
                            <xsl:with-param name="attr" select="map:keys($custom)"/>
                            <xsl:with-param name="custom" select="$custom"/>
                        </xsl:call-template>
                        <orig>
                            <xsl:call-template name="elem">
                                <xsl:with-param name="elem" select="$elem"/>
                            </xsl:call-template>
                        </orig>
                        <reg>
                            <xsl:value-of
                                select="replace(map:get($custom, 'normal'), '\\u0020', ' ')"/>
                        </reg>
                    </choice>
                </rs>
            </xsl:when>
            <xsl:when test="@type = 'TU_status'">
                <rs>
                    <xsl:attribute name="type">workerStatus</xsl:attribute>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </rs>
            </xsl:when>
            <xsl:when test="@type = 'TU_duree'">
                <rs>
                    <xsl:attribute name="type">duration</xsl:attribute>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </rs>
            </xsl:when>
            <xsl:when test="@type = 'TU_produit'">
                <rs>
                    <xsl:attribute name="type">product</xsl:attribute>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </rs>
            </xsl:when>
            <xsl:when test="@type = 'TU_statutMatrimonial'">
                <rs>
                    <xsl:attribute name="type">matStatus</xsl:attribute>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </rs>
            </xsl:when>
            <xsl:when test="@type = 'TU_tache'">
                <rs>
                    <xsl:attribute name="type">task</xsl:attribute>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </rs>
            </xsl:when>
            <xsl:when test="@type = 'TU_typeRemuneration'">
                <rs>
                    <xsl:attribute name="type">revenue-type</xsl:attribute>
                    <xsl:call-template name="attr">
                        <xsl:with-param name="attr" select="map:keys($custom)"/>
                        <xsl:with-param name="custom" select="$custom"/>
                    </xsl:call-template>
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </rs>
            </xsl:when>
            <xsl:when test="@type = 'comment'">
                <xsl:call-template name="elem">
                    <xsl:with-param name="elem" select="$elem"/>
                </xsl:call-template>
                <xsl:comment><xsl:value-of select="replace(replace(replace(map:get($custom, 'comment'), '\\u0020', ' '), '\\u0027', ''''), '\\u0022', '&quot;')"/></xsl:comment>
            </xsl:when>
            <!-- END OF CUSTOM TAGS -->

            <xsl:otherwise>
                <xsl:element name="{@type}">
                    <xsl:call-template name="elem">
                        <xsl:with-param name="elem" select="$elem"/>
                    </xsl:call-template>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:apply-templates
            select="following-sibling::local:m[@pos = 'e' and @o = $o]/following-sibling::node()[1][self::text()]"
        />
    </xsl:template>

    <xd:doc>
        <xd:desc>TIME US - Create attributes</xd:desc>
        <xd:param name="attr"/>
        <xd:param name="custom"/>
    </xd:doc>
    <xsl:template name="attr">
        <xsl:param name="custom"/>
        <xsl:param name="attr"/>
        <xsl:for-each select="$attr">
            <xsl:if test=". != 'length' and . != ''">
                <xsl:choose>
                    <xsl:when test=". = 'continued'">
                        <xsl:attribute name="rend">multiline</xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="{.}">
                            <xsl:value-of select="replace(map:get($custom, .), '\\u0020', ' ')"/>
                        </xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xd:doc>
        <xd:desc>Process what's between a pair of local:m</xd:desc>
        <xd:param name="elem"/>
    </xd:doc>
    <xsl:template name="elem">
        <xsl:param name="elem"/>

        <xsl:choose>
            <xsl:when test="$elem//local:m">
                <xsl:apply-templates select="$elem/local:t/text()[not(preceding-sibling::local:m)]"/>
                <xsl:apply-templates
                    select="
                        $elem/local:t/local:m[@pos = 's']
                        [not(preceding-sibling::local:m[1][@pos = 's'])]"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$elem/local:t/node()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xd:doc>
        <xd:desc>Leave out possibly unwanted parts</xd:desc>
    </xd:doc>
    <xsl:template match="p:Metadata" mode="text"/>


    <xd:doc>
        <xd:desc>Text nodes to be copied</xd:desc>
    </xd:doc>
    <xsl:template match="text()">
        <xsl:value-of select="."/>
    </xsl:template>


</xsl:stylesheet>
