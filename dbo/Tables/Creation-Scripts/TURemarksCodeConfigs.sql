SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TURemarksCodeConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CombinationCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Class] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TURemarksCodeConfigs]  WITH CHECK ADD  CONSTRAINT [ETURemarksCodeConfig_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[TURemarksCodeConfigs] CHECK CONSTRAINT [ETURemarksCodeConfig_Portfolio]
GO
