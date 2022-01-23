SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Logoes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityType] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[LogoImageFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[LogoImageFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[LogoImageFile_Content] [varbinary](82) NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PartyId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Logoes]  WITH CHECK ADD  CONSTRAINT [ELogo_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[Logoes] CHECK CONSTRAINT [ELogo_Party]
GO
ALTER TABLE [dbo].[Logoes]  WITH CHECK ADD  CONSTRAINT [ELogo_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[Logoes] CHECK CONSTRAINT [ELogo_Portfolio]
GO
